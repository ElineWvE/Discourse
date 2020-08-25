# frozen_string_literal: true

class VanillaBodyParser
  def self.configure(lookup:, uploader:, host:, uploads_path:)
    @@lookup = lookup
    @@uploader = uploader
    @@host = host
    @@uploads_path = uploads_path
  end

  def initialize(row, user_id)
    @row = row
    @user_id = user_id
  end

  def parse
    return clean_up(@row['Body']) unless rich?

    full_text = json.each_with_index.map(&method(:parse_fragment)).join('')

    normalize full_text
  end

  private

  def clean_up(text)
    text.gsub(/<\/?font[^>]*>/, '').gsub(/<\/?span[^>]*>/, '').gsub(/<\/?div[^>]*>/, '').gsub(/^ +/, '').gsub(/ +/, ' ')
  end

  def rich?
    @row['Format'] == 'Rich'
  end

  def json
    return nil unless rich?
    @json ||= JSON.parse(@row['Body']).map(&:deep_symbolize_keys)
  end

  def parse_fragment(fragment, index)
    text = fragment.keys.one? && fragment[:insert].is_a?(String) ? fragment[:insert] : rich_parse(fragment)

    text = parse_code(text, fragment, index)
    text = parse_list(text, fragment, index)

    text
  end

  def rich_parse(fragment)
    insert = fragment[:insert]

    return parse_mention(insert[:mention]) if insert.respond_to?(:dig) && insert.dig(:mention, :userID)

    return parse_formatting(fragment) if fragment[:attributes]

    embed_type = insert.dig(:'embed-external', :data, :embedType)

    quoting = embed_type == 'quote'
    return parse_quote(insert) if quoting

    embed = embed_type.in? ['image', 'link', 'file']
    parse_embed(insert) if embed
  end

  def parse_mention(mention)
    user = user_from_imported_id(mention[:userID])
    username = user&.username || mention[:name]
    "@#{username}"
  end

  def user_from_imported_id(imported_id)
    user_id = @@lookup.user_id_from_imported_user_id(imported_id)
    User.find(user_id) if user_id
  end

  def parse_formatting(fragment)
    insert = fragment[:insert]
    attributes = fragment[:attributes]

    text = fragment[:insert]

    text = "<a href=\"#{attributes[:link]}\">#{text}</a>" if attributes[:link]
    text = "<i>#{text}</i>" if attributes[:italic]
    text = "<b>#{text}</b>" if attributes[:bold]

    text
  end

  # In the Quill format used by Vanilla Forums, a line is rendered as `code`
  # when it's followed by a fragment with attributes: {'code-block': true}.
  # So we open our ``` block when the next fragment has a 'code-block'
  # attribute and the previous one didn't and we close the ``` block when
  # the second next fragment does not contain the 'code-block' attribute
  def parse_code(text, fragment, index)
    next_fragment = next_fragment(index)

    next_code = next_fragment.dig(:attributes, :'code-block')
    if next_code
      previous_fragment = previous_fragment(index)
      previous_code = previous_fragment.dig(:attributes, :'code-block')

      # if next is code and previous is not, prepend ```
      text = "\n```#{text}" unless previous_code
    end

    current_code = fragment.dig(:attributes, :'code-block')

    if current_code
      second_next_fragment = second_next_fragment(index)
      second_next_code = second_next_fragment.dig(:attributes, :'code-block')

      # if current is code and 2 after is not, prepend ```
      text = "\n```#{text}" unless second_next_code
    end

    text
  end

  def parse_list(text, fragment, index)
    next_fragment = next_fragment(index)

    next_list = next_fragment.dig(:attributes, :list, :type)
    if next_list
      # if next is list, prepend <li>
      text = '<li>' + text

      previous_fragment = previous_fragment(index)
      previous_list = previous_fragment.dig(:attributes, :list, :type)

      # if next is list and previous is not, prepend <ol> or <ul>
      list_tag = next_list == 'ordered' ? '<ol>' : '<ul>'
      text = "\n#{list_tag}\n#{text}" unless previous_list
    end

    current_list = fragment.dig(:attributes, :list, :type)

    if current_list
      # if current is list prepend </li>
      tag_closings = '</li>'

      second_next_fragment = second_next_fragment(index)
      second_next_list = second_next_fragment.dig(:attributes, :list, :type)

      # if current is list and 2 after is not, prepend </ol>
      list_tag = current_list == 'ordered' ? '</ol>' : '</ul>'
      tag_closings = "#{tag_closings}\n#{list_tag}" unless second_next_list

      text = tag_closings + text
    end

    text
  end

  def next_fragment(index)
    json[index + 1] || {}
  end

  def previous_fragment(index)
    json[index - 1] || {}
  end

  def second_next_fragment(index)
    json[index + 2] || {}
  end

  def parse_quote(insert)
    embed = insert.dig(:'embed-external', :data)

    import_post_id = "#{embed[:recordType]}##{embed[:recordID]}"
    topic = @@lookup.topic_lookup_from_imported_post_id(import_post_id)
    user = user_from_imported_id(embed.dig(:insertUser, :userID))

    quote_info = topic && user ? "=\"#{user.username}, post: #{topic[:post_number]}, topic: #{topic[:topic_id]}\"" : ''

    "[quote#{quote_info}]\n#{embed[:body]}\n[/quote]\n\n"""
  end

  def parse_embed(insert)
    embed = insert.dig(:'embed-external', :data)

    url = embed[:url]

    if /https?\:\/\/#{@@host}\/uploads\/.*/.match?(url)
      remote_path = url.scan(/uploads\/(.*)/)
      path = File.join(@@uploads_path, remote_path)

      upload = @@uploader.create_upload(@user_id, path, embed[:name])

      if upload&.persisted?
        return "\n" + @@uploader.html_for_upload(upload, embed[:name]) + "\n"
      else
        puts "Failed to upload #{path}"
        puts upload.errors.full_messages.join(', ') if upload
      end
    end

    "\n[#{embed[:name]}](#{url})\n"
  end

  def normalize(full_text)
    code_matcher = /```(.*\n)+```/
    code_block = full_text[code_matcher]
    full_text[code_matcher] = '{{{CODE_BLOCK}}}' if code_block
    full_text = double_new_lines(full_text)
    full_text['{{{CODE_BLOCK}}}'] = code_block if code_block
    full_text
  end

  def double_new_lines(text)
    text.split("\n").map(&:strip).map(&:presence).compact.join("\n\n")
  end
end
