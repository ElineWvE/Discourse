class PostValidator < ActiveModel::Validator
  def validate(record)
    raw_quality(record)
    max_mention_validator(record)
    max_images_validator(record)
    max_links_validator(record)
    unique_post_validator(record)
  end

  def raw_quality(post)
    sentinel = TextSentinel.body_sentinel(post.raw)
    post.errors.add(:raw, I18n.t(:is_invalid)) unless sentinel.valid?
  end

  # Ensure maximum amount of mentions in a post
  def max_mention_validator(post)
    if acting_user_is_trusted?(post)
      add_error_if_count_exceeded(post, :too_many_mentions, post.raw_mentions.size, SiteSetting.max_mentions_per_post)
    else
      add_error_if_count_exceeded(post, :too_many_mentions_newuser, post.raw_mentions.size, SiteSetting.newuser_max_mentions_per_post)
    end
  end

  # Ensure new users can not put too many images in a post
  def max_images_validator(post)
    add_error_if_count_exceeded(post, :too_many_images, post.image_count, SiteSetting.newuser_max_images) unless acting_user_is_trusted?(post)
  end

  # Ensure new users can not put too many links in a post
  def max_links_validator(post)
    add_error_if_count_exceeded(post, :too_many_links, post.link_count, SiteSetting.newuser_max_links) unless acting_user_is_trusted?(post)
  end

  # Stop us from posting the same thing too quickly
  def unique_post_validator(post)
    return if SiteSetting.unique_posts_mins == 0
    return if post.acting_user.admin? || post.acting_user.moderator?

    # If the post is empty, default to the validates_presence_of
    return if post.raw.blank?

    if $redis.exists(post.unique_post_key)
      post.errors.add(:raw, I18n.t(:just_posted_that))
    end
  end

  private

  def acting_user_is_trusted?(post)
    post.acting_user.present? && post.acting_user.has_trust_level?(:basic)
  end

  def add_error_if_count_exceeded(post, key_for_translation, current_count, max_count)
    post.errors.add(:base, I18n.t(key_for_translation, count: max_count)) if current_count > max_count
  end
end
