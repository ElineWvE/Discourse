# frozen_string_literal: true

class QuoteRewriter
  def initialize(user_id, old_username, new_username, avatar_img)
    @user_id = user_id
    @old_username = old_username
    @new_username = new_username
    @avatar_img = avatar_img
  end

  def rewrite_raw(raw)
    pattern =
      Regexp.union(
        /(?<pre>\[quote\s*=\s*["'']?.*username:)#{old_username}(?<post>\,?[^\]]*\])/i,
        /(?<pre>\[quote\s*=\s*["'']?)#{old_username}(?<post>\,?[^\]]*\])/i,
      )

    raw.gsub(pattern, "\\k<pre>#{new_username}\\k<post>")
  end

  def rewrite_cooked(cooked)
    pattern = /(?<=\s)#{PrettyText::Helpers.format_username(old_username)}(?=:)/i

    cooked
      .css("aside.quote")
      .each do |aside|
        next unless div = aside.at_css("div.title")

        username_replaced = false

        aside["data-username"] = new_username if aside["data-username"] == old_username

        div.children.each do |child|
          if child.text?
            content = child.content
            username_replaced = content.gsub!(pattern, new_username).present?
            child.content = content if username_replaced
          end
        end

        if username_replaced || quotes_correct_user?(aside)
          div.at_css("img.avatar")&.replace(avatar_img)
        end
      end
  end

  def rewrite_raw_display_name(raw, old_display_name, new_display_name)
    pattern = /(?<pre>\[quote\s*=\s*["'']?)#{old_display_name}(?<post>\,[^\]]*username[^\]]*\])/i

    raw.gsub(pattern, "\\k<pre>#{new_display_name}\\k<post>")
  end

  def rewrite_cooked_display_name(cooked, old_display_name, new_display_name)
    pattern = /(?<=\s)#{PrettyText::Helpers.format_username(old_display_name)}(?=:)/i

    cooked
      .css("aside.quote")
      .each do |aside|
        next unless div = aside.at_css("div.title")

        div.children.each do |child|
          if child.text?
            content = child.content
            display_name_replaced = content.gsub!(pattern, new_display_name).present?
            child.content = content if display_name_replaced
          end
        end
      end
  end

  private

  attr_reader :user_id, :old_username, :new_username, :avatar_img

  def quotes_correct_user?(aside)
    Post.exists?(topic_id: aside["data-topic"], post_number: aside["data-post"], user_id: user_id)
  end
end
