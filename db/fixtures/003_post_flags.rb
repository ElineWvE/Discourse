# frozen_string_literal: true

PostFlag.seed do |s|
  s.id = 3
  s.name = "off_topic"
  s.position = 2
  s.system = true
  s.topic_type = false
  s.notify_type = true
  s.auto_action_type = true
  s.custom_type = false
end
PostFlag.seed do |s|
  s.id = 4
  s.name = "inappropriate"
  s.position = 3
  s.system = true
  s.topic_type = true
  s.notify_type = true
  s.auto_action_type = true
  s.custom_type = false
end
PostFlag.seed do |s|
  s.id = 8
  s.name = "spam"
  s.position = 4
  s.system = true
  s.topic_type = true
  s.notify_type = true
  s.auto_action_type = true
  s.custom_type = false
end
PostFlag.seed do |s|
  s.id = 6
  s.name = "notify_user"
  s.position = 0
  s.system = true
  s.topic_type = false
  s.notify_type = false
  s.auto_action_type = false
  s.custom_type = true
end
PostFlag.seed do |s|
  s.id = 7
  s.name = "notify_moderators"
  s.position = 1
  s.system = true
  s.topic_type = true
  s.notify_type = true
  s.auto_action_type = true
  s.custom_type = true
end
PostFlag.seed do |s|
  s.id = 10
  s.name = "illegal"
  s.position = 5
  s.system = true
  s.topic_type = true
  s.notify_type = true
  s.auto_action_type = true
  s.custom_type = true
end
