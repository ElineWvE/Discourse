# frozen_string_literal: true

Fabricator(:poll) do
  post
  name { sequence(:name) { |i| "Poll #{i}" } }
end

Fabricator(:poll_option) do
  poll
  html { sequence(:html) { |i| "Poll Option #{i}" } }
  digest { sequence(:digest) { |i| "#{i}" } }
end

Fabricator(:poll_vote) do
  poll
  poll_option
  user
end
