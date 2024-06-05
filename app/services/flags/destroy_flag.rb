# frozen_string_literal: true

class Flags::DestroyFlag
  include Service::Base

  model :flag
  policy :invalid_access

  transaction do
    step :destroy
    step :log
  end

  private

  def fetch_flag(id:)
    Flag.find(id)
  end

  def invalid_access(guardian:, flag:)
    guardian.can_edit_flag?(flag)
  end

  def destroy(flag:)
    flag.destroy!
  end

  def log(guardian:, flag:)
    StaffActionLogger.new(guardian.user).log_custom(
      "delete_flag",
      {
        name: flag.name,
        description: flag.description,
        applies_to: flag.applies_to,
        enabled: flag.enabled,
      },
    )
  end
end
