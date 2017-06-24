require "pry"

class Post
  attr_reader :title

  def initialize(markdown)
    @markdown = markdown
    @title = get_title
  end

  def get_title
    title_line = find_title_line
    title_line.slice!("# ")
    title_line
  end

  def find_title_line(line_number = 0)
    return markdown_lines[line_number] if header?(markdown_lines[line_number])
    find_title_line(line_number + 1)
  end

  def to_html
    current_paragraph = ""

    html_lines = replace_code(markdown_lines_without_comments)

    html_lines = html_lines.map do |md_line|
      if header?(md_line)
        html_header(md_line)
      elsif md_line == ""
        if current_paragraph.empty?
          md_line
        else
          html = "<p>#{current_paragraph}</p>" + "\n"
          current_paragraph = ""
          html
        end
      else
        current_paragraph = current_paragraph + " " + md_line
        nil
      end
    end

    if !current_paragraph.empty?
      html_lines << "<p>#{current_paragraph}</p>"
    end
    add_html_outline(html_lines.compact.join("\n"))
  end

  def add_html_outline(html)
    "<html> \
    <head> \
    <style>code { white-space: pre; }</style> \
    </head> \
    <body>#{html}</body> \
    </html>"
  end

  def replace_code(markdown_lines)
    # find beginning of code snippet
    # return if no code
    code_start = markdown_lines.index("```")
    return markdown_lines if code_start.nil?

    # combine until end of code snippet
    code_block = ""
    code_end = nil
    i = 1
    loop do
      line = markdown_lines[code_start + i]
      if line === "```"
        code_end = code_start + i
        break
      end

      code_block << line + "<br />"
      i += 1
    end
    code_block = "<code>#{code_block}</code>"

    # replace all of those lines in array
    markdown_lines.slice!(code_start..code_end)
    markdown_lines.insert(code_start, code_block)

    # repeat
    replace_code(markdown_lines)
  end

  def header?(md_line)
    /^#+ /.match(md_line)
  end

  def comment?(md_line)
    /^<!--/.match(md_line)
  end

  def html_header(md_line)
    header_value = md_line.split(" ").first.chars.count
    md_line.slice!("#"*header_value + " ")

    "<h#{header_value}>#{md_line}</h#{header_value}>"
  end

  def html_section_header(md_line)
    md_line.slice!("## ")
    "<h2>#{md_line}</h2>"
  end

  def html_link
    "<a href=''>#{@title}</a>"
  end

  def markdown_lines
    @markdown.split("\n")
  end

  def markdown_lines_without_comments
    markdown_lines.reject { |line| comment?(line) }
  end
end

# select all md files in /posts
Dir["posts/*.md"].each do |file_name|
  next if file_name.include? "template.md"

  markdown = File.read(file_name)
  post = Post.new(markdown)

  html = post.to_html

  html_page = File.new("html_posts/#{post.title.downcase.gsub(" ", "_")}.html", "w+")
  html_page.puts html
  html_page.close

  # update index posts section with link to new page
end
