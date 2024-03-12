# frozen_string_literal: true

class ProblemCheck::EmailPollingErroredRecently < ProblemCheck
  self.priority = "low"

  def call
    return no_problem if !(polling_error_count > 0)

    problem
  end

  private

  def polling_error_count
    @polling_error_count ||= Jobs::PollMailbox.errors_in_past_24_hours
  end

  def translation_key
    "dashboard.email_polling_errored_recently"
  end

  def translation_data
    { count: polling_error_count }
  end
end
