class WebHookEventType < ActiveRecord::Base
  TOPIC = 1
  POST = 2

  has_and_belongs_to_many :web_hooks

  default_scope { order('id ASC') }

  validates :name, presence: true, uniqueness: true
end

# == Schema Information
#
# Table name: web_hook_event_types
#
#  id   :integer          not null, primary key
#  name :string           not null
#
# Indexes
#
#  index_web_hook_event_types_on_name  (name) UNIQUE
#
