require_dependency "file_helper"

class AvatarUploadService

  attr_accessor :source
  attr_reader :filesize, :filename, :file

  def initialize(file, source)
    @source = source
    @file, @filename, @filesize = construct(file)
  end

  def construct(file)
    case source
    when :url
      tmp = FileHelper.download(file, SiteSetting.max_image_size_kb.kilobytes, "discourse-avatar")
      [tmp, File.basename(URI.parse(file).path), tmp.size]
    when :image
      [file.tempfile, file.original_filename, file.tempfile.size]
    end
  end

end
