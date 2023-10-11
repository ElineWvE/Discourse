# frozen_string_literal: true

module Jobs
  class CleanUpTags < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      return unless SiteSetting.automatically_clean_unused_tags
      Tag.unused.destroy_all
    end
  end
end
