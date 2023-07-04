# frozen_string_literal: true

class Downloads
  FOLDER = "tmp/downloads"
  TIMEOUT = 10

  def self.wait_for_download
    Timeout.timeout(TIMEOUT) { sleep 0.1 until downloaded? }
  end

  def self.clear
    FileUtils.rm_rf(FOLDER)
  end

  private

  # fixme andrei use it instead of reading the name of the file from the page
  def self.downloads
    Dir[FOLDER]
  end

  def self.downloaded?
    !downloading? && downloads.any?
  end

  def self.downloading?
    downloads.grep(/\.crdownload$/).any?
  end

  private_class_method :downloads, :downloaded?, :downloading?
end
