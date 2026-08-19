module MarkdownHelper
  # Markdown tối giản -> HTML an toàn (heading, bold, italic, list, code, paragraph).
  def simple_markdown(text)
    return "" if text.blank?

    html = []
    list_open = false
    ol_open = false

    close_lists = lambda do
      if list_open then html << "</ul>"; list_open = false end
      if ol_open then html << "</ol>"; ol_open = false end
    end

    text.to_s.each_line do |raw|
      line = raw.chomp
      case line
      when /\A\s*#{'#'}{3,}\s+(.*)/ # ### heading
        close_lists.call
        html << "<h4 class='md-h'>#{inline(Regexp.last_match(1))}</h4>"
      when /\A\s*#{'#'}{1,2}\s+(.*)/ # # / ## heading
        close_lists.call
        html << "<h3 class='md-h'>#{inline(Regexp.last_match(1))}</h3>"
      when /\A\s*[-*]\s+(.*)/ # bullet
        unless list_open then close_lists.call; html << "<ul class='md-ul'>"; list_open = true end
        html << "<li>#{inline(Regexp.last_match(1))}</li>"
      when /\A\s*\d+[.)]\s+(.*)/ # numbered
        unless ol_open then close_lists.call; html << "<ol class='md-ol'>"; ol_open = true end
        html << "<li>#{inline(Regexp.last_match(1))}</li>"
      when /\A\s*\z/ # blank
        close_lists.call
      else
        close_lists.call
        html << "<p class='md-p'>#{inline(line)}</p>"
      end
    end
    close_lists.call
    html.join("\n").html_safe
  end

  private

  def inline(str)
    escaped = ERB::Util.html_escape(str)
    escaped = escaped.gsub(/\*\*(.+?)\*\*/, '<strong>\1</strong>')
    escaped = escaped.gsub(/(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)/, '<em>\1</em>')
    escaped = escaped.gsub(/`(.+?)`/, '<code>\1</code>')
    escaped = escaped.gsub(/_(.+?)_/, '<em>\1</em>')
    escaped.html_safe
  end
end
