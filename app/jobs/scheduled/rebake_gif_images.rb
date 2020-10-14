# frozen_string_literal: true

module Jobs
  class RebakeGifImages < ::Jobs::Scheduled
    every 1.hour

    MAX_PROCESSED_GIF_IMAGES ||= 200

    def execute(args)
      Upload
        .where("original_filename LIKE '%.gif'")
        .where(animated: nil)
        .limit(MAX_PROCESSED_GIF_IMAGES)
        .find do |upload|
        uri = Discourse.store.path_for(upload) || upload.url
        upload.update!(animated: FastImage.animated?(uri))
        upload.optimized_images.destroy_all if upload.animated
      end

      nil
    end
  end
end
