# frozen_string_literal: true

module Demon
end

# intelligent fork based demonizer
class Demon::Base
  def self.demons
    @demons
  end

  def self.start(count = 1, verbose: false)
    @demons ||= {}
    count.times { |i| (@demons["#{prefix}_#{i}"] ||= new(i, verbose: verbose)).start }
  end

  def self.stop
    return unless @demons
    @demons.values.each { |demon| demon.stop }
  end

  def self.restart
    return unless @demons
    @demons.values.each do |demon|
      demon.stop
      demon.start
    end
  end

  def self.ensure_running
    @demons.values.each { |demon| demon.ensure_running }
  end

  def self.kill(signal)
    return unless @demons
    @demons.values.each { |demon| demon.kill(signal) }
  end

  def self.logger
    @@logger ||= Logger.new(STDERR)
  end

  def self.logger=(new_logger)
    @@logger = new_logger
  end

  def self.log(message, level: info)
    logger.public_send(level, message)
  end

  def self.log_in_trap(message, level: :info)
    # We use an IO pipe and log messages using the logger in a seperate thread to avoid the `log writing failed. can't be called from trap context`
    # error message that is raised when trying to log from within a `Signal.trap` block.
    if !defined?(@logger_read_pipe)
      @@logger_read_pipe, @@logger_write_pipe = IO.pipe

      @@logger_thread =
        Thread.new do
          begin
            while readable_io = IO.select([@@logger_read_pipe])
              logger.public_send(level, readable_io.first[0].gets.strip)
            end
          rescue => e
            logger.error("Error in demon logger thread: #{e.message}\n#{e.backtrace.join("\n")}")
          end
        end
    end

    @@logger_write_pipe.puts(message)
  end

  attr_reader :pid, :parent_pid, :started, :index
  attr_accessor :stop_timeout

  def initialize(index, rails_root: nil, parent_pid: nil, verbose: false)
    @index = index
    @pid = nil
    @parent_pid = parent_pid || Process.pid
    @started = false
    @stop_timeout = 10
    @rails_root = rails_root || Rails.root
    @verbose = verbose
  end

  def log(message, level: :info)
    self.class.log(message, level:)
  end

  def log_in_trap(message, level: :info)
    self.class.log_in_trap(message, level:)
  end

  def pid_file
    "#{@rails_root}/tmp/pids/#{self.class.prefix}_#{@index}.pid"
  end

  def alive?(pid = nil)
    pid ||= @pid
    if pid
      Demon::Base.alive?(pid)
    else
      false
    end
  end

  def kill(signal)
    Process.kill(signal, @pid)
  end

  def stop_signal
    "HUP"
  end

  def stop
    @started = false

    if @pid
      Process.kill(stop_signal, @pid)

      wait_for_stop =
        lambda do
          timeout = @stop_timeout

          while alive? && timeout > 0
            timeout -= (@stop_timeout / 10.0)
            sleep(@stop_timeout / 10.0)
            begin
              Process.waitpid(@pid, Process::WNOHANG)
            rescue StandardError
              -1
            end
          end

          begin
            Process.waitpid(@pid, Process::WNOHANG)
          rescue StandardError
            -1
          end
        end

      wait_for_stop.call

      if alive?
        log("Process would not terminate cleanly, force quitting. pid: #{@pid} #{self.class}")
        Process.kill("KILL", @pid)
      end

      wait_for_stop.call

      @pid = nil
      @started = false
    end
  end

  def ensure_running
    return unless @started

    if !@pid
      @started = false
      start
      return
    end

    dead =
      begin
        Process.waitpid(@pid, Process::WNOHANG)
      rescue StandardError
        -1
      end

    if dead
      log("Detected dead worker #{@pid}, restarting...")
      @pid = nil
      @started = false
      start
    end
  end

  def start
    return if @pid || @started

    if existing = already_running?
      # should not happen ... so kill violently
      log("Attempting to kill pid #{existing}")
      Process.kill("TERM", existing)
    end

    @started = true
    run
  end

  def run
    @pid =
      fork do
        Process.setproctitle("discourse #{self.class.prefix}")
        monitor_parent
        establish_app
        after_fork
      end
    write_pid_file
  end

  def already_running?
    if File.exist? pid_file
      pid = File.read(pid_file).to_i
      return pid if Demon::Base.alive?(pid)
    end

    nil
  end

  def self.alive?(pid)
    Process.kill(0, pid)
    true
  rescue StandardError
    false
  end

  private

  def verbose(msg)
    puts msg if @verbose
  end

  def write_pid_file
    verbose("writing pid file #{pid_file} for #{@pid}")
    FileUtils.mkdir_p(@rails_root + "tmp/pids")
    File.open(pid_file, "w") { |f| f.write(@pid) }
  end

  def delete_pid_file
    File.delete(pid_file)
  end

  def monitor_parent
    Thread.new do
      while true
        begin
          unless alive?(@parent_pid)
            Process.kill "TERM", Process.pid
            sleep 10
            Process.kill "KILL", Process.pid
          end
        rescue => e
          log("URGENT monitoring thread had an exception #{e}")
        end
        sleep 1
      end
    end
  end

  def suppress_stdout
    true
  end

  def suppress_stderr
    true
  end

  def establish_app
    Discourse.after_fork if defined?(Discourse)

    Signal.trap("HUP") do
      begin
        delete_pid_file
      ensure
        # TERM is way cleaner than exit
        Process.kill("TERM", Process.pid)
      end
    end

    # keep stuff simple for now
    $stdout.reopen("/dev/null", "w") if suppress_stdout
    $stderr.reopen("/dev/null", "w") if suppress_stderr
  end

  def after_fork
  end
end
