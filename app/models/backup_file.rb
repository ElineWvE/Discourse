class BackupFile
  include ActiveModel::SerializerSupport

  attr_reader :filename,
              :size,
              :last_modified,
              :source

  def initialize(filename:, size:, last_modified:, source: nil)
    @filename = filename
    @size = size
    @last_modified = last_modified
    @source = source
  end
end
