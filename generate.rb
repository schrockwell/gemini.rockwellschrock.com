#! /usr/bin/env ruby

require 'date'
require 'time'
require 'fileutils'
require 'pathname'

CONTENT_INPUT_DIR = 'content'
WEB_INPUT_DIR = 'web'
WEB_OUTPUT_DIR = '_site'
GEMINI_INPUT_DIR = 'gemini'
GEMINI_OUTPUT_DIR = '_capsule'
LAYOUT_PATH = WEB_INPUT_DIR + "/_layout.html"
GEMINI_HOST = 'gemini://gmi.schrockwell.com'
WEB_HOST = 'https://www.schrockwell.com'
SITE_TITLE = 'Rockwell Schrock'

def preprocess_gemtext(gemtext, scope)
  selected = true

  gemtext.split("\n").map do |line|
    if line == '<web>'
      selected = (scope == :web)
      nil
    elsif line == '<gemini>'
      selected = (scope == :gemini)
      nil
    elsif line == '</web>' || line == '</gemini>'
      selected = true
      nil
    elsif selected
      line
    else
      nil
    end
  end.compact.join("\n")
end

def lex_gemtext(gemtext)
  in_pre = false

  gemtext.split("\n").map do |line|
    if line.start_with?("```")
      in_pre = !in_pre
      { type: :toggle_pre }
    elsif in_pre
      { type: :text, text: line }
    elsif line.start_with?("# ")
      { type: :h1, text: line[2..] }
    elsif line.start_with?("## ")
      { type: :h2, text: line[3..] }
    elsif line.start_with?("### ")
      { type: :h3, text: line[4..] }
    elsif line.start_with?("> ")
      { type: :quote, text: line[2..] }
    elsif line.start_with?("* ")
      { type: :li, text: line[2..] }
    elsif line.start_with?("=> ")
      words = line[3..].split(" ")
      url = words[0]
      if words.length == 1
        { type: :link, url: url, text: url }
      else
        { type: :link, url: url, text: words[1..].join(" ") }
      end
    elsif line.start_with?('---')
      # Custom! Not part of the gemtext spec
      { type: :hr }
    else
      { type: :text, text: line }
    end
  end
end

def gallery_image?(token)
  return false unless token[:type] == :link
  extension = token[:url].split(".").last
  !token[:url].start_with?("http") && ['jpg', 'jpeg', 'png', 'gif', 'webp'].include?(extension)
end

def parse_gemtext(tokens)
  i = 0
  blocks = []

  while i < tokens.length
    token = tokens[i]

    case token[:type]
    when :toggle_pre
      closing_pre = tokens[i+1..].index { |t| t[:type] == :toggle_pre }
      text = tokens[i+1..i+closing_pre].map { |t| t[:text] }.join("\n")
      blocks << { type: :pre, text: text }
      i += closing_pre + 1

    when :li
      all_items = tokens[i..].take_while { |t| t[:type] == :li }
      items_text = all_items.map { |t| t[:text] }
      blocks << { type: :ul, items: items_text }
      i += all_items.length - 1

    when :quote
      all_quotes = tokens[i..].take_while { |t| t[:type] == :quote }
      text = all_quotes.map { |t| t[:text] }.join("\n")
      blocks << { type: :blockquote, text: text }
      i += all_quotes.length - 1

    when :link
      if gallery_image?(token)
        all_images = tokens[i..].take_while { |t| gallery_image?(t) }
        blocks << { type: :gallery, text: '', images: all_images }
        i += all_images.length - 1
      else
        blocks << token
      end
    
    else
      blocks << token
    end

    i += 1
  end

  blocks
end

def render_html(parsed)
  parsed.map do |block|
    safe_text = block[:text].to_s.gsub("<", "&lt;").gsub(">", "&gt;")

    case block[:type]
    when :h1
      "<h1>#{safe_text}</h1>"
    when :h2
      "<h2>#{safe_text}</h2>"
    when :h3
      "<h3>#{safe_text}</h3>"
    when :pre
      "<pre>#{safe_text}</pre>"
    when :ul
      items = block[:items].map { |item| "  <li>#{item}</li>" }.join("\n")
      "<ul>\n#{items}\n</ul>"
    when :blockquote
      "<blockquote>#{safe_text}</blockquote>"
    when :link
      extension = block[:url].split(".").last
      if extension == "gmi"
        # Replace .gmi with .html only at end of url
        url = block[:url].gsub(/\.gmi$/, ".html")
        "<a href=\"#{url}\">#{safe_text}</a>"
      else
        "<a href=\"#{block[:url]}\">#{safe_text}</a>"
      end

    when :gallery
      figures = block[:images].map do |image|
        image_text = image[:text].gsub("<", "&lt;").gsub(">", "&gt;")
        """
        <figure>
          <a href=\"#{image[:url]}\">
            <img src=\"#{image[:url]}\" alt=\"#{image_text}\">
          </a>
          <figcaption>#{image_text}</figcaption>
        </figure>
        """
      end.join("\n")
      
      "<div class=\"gallery\">#{figures}</div>"

    when :hr
      '<hr/>'

    else
      "<p>#{safe_text}</p>"
    end
  end.join("\n")
end

def gemtext2tokens(gemtext, scope)
  gemtext = preprocess_gemtext(gemtext, scope)
  tokens = lex_gemtext(gemtext)
  parse_gemtext(tokens)
end

def render_template(template, assigns)
  assigns.each do |key, value|
    template.gsub!("{{#{key}}}", value)
  end
  template
end

def find_first_heading(tokens, default="Untitled")
  heading = tokens.select { |t| t[:type] == :h1 || t[:type] == :h2  || t[:type] == :h3 }.first
  heading ? heading[:text] : default
end

def copy_file(file, input_dir, output_dir)
  return 0 if File.basename(file).start_with?("_")

  if process_photo(file, input_dir, output_dir)
    1
  else
    out_file = file.gsub(input_dir, output_dir)
    dir = File.dirname(out_file)
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    FileUtils.cp(file, out_file)
    1
  end
end

def process_photo(file, input_dir, output_dir)
  return false unless file.end_with?(".jpg", ".jpeg")

  # Run imagemagick and resize to 2000px max dimension, webp, and sharpen
  out_file = file.gsub(input_dir, output_dir)

  FileUtils.mkdir_p(File.dirname(out_file))
  cmd = "convert '#{file}' -resize 1200x1200\\> -sharpen 0x0.7 '#{out_file}'"
  system(cmd)
end

def build_web_site
  count = 0
  FileUtils.rm_rf(WEB_OUTPUT_DIR)
  rss_posts = []

  # Recursively process all files in the /content directory and output to /html
  Dir.glob("#{CONTENT_INPUT_DIR}/**/*").each do |file|
    if File.file?(file)
      if file.end_with?(".gmi")
        gemtext = File.read(file)
        tokens = gemtext2tokens(gemtext, :web)

        # Determine title
        h1_title = find_first_heading(tokens).dup
        title = h1_title.dup
        title << " - #{SITE_TITLE}" unless title == SITE_TITLE
        
        # Render HTML in layout
        layout = File.read(LAYOUT_PATH)
        content = render_html(tokens)
        gemini_url = GEMINI_HOST + file.gsub(CONTENT_INPUT_DIR, "").gsub("/index.gmi", "/")
        html = render_template(layout, title: title, content: content, gemini_url: gemini_url)

        # Output to file
        html_path = file.gsub(CONTENT_INPUT_DIR, WEB_OUTPUT_DIR).gsub(".gmi", ".html")
        dir = File.dirname(html_path)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        File.write(html_path, html)
        
        count += 1

        # Add to RSS feed
        if file.include?("/posts/")
          # Convery basename to date
          if File.basename(file).match?(/\d{4}-\d{2}-\d{2}/)
            date = Date.parse(File.basename(file)[0..9])
            rss_posts << { title: h1_title, url: WEB_HOST + html_path.gsub(WEB_OUTPUT_DIR, ""), date: date, body: content }
          end
        end
      else
        count += copy_file(file, CONTENT_INPUT_DIR, WEB_OUTPUT_DIR)
      end
    end
  end

  # Copy everything from /web to /_site, except if the file starts with an underscore
  Dir.glob("#{WEB_INPUT_DIR}/**/*").each do |file|
    if File.file?(file)
      count += copy_file(file, WEB_INPUT_DIR, WEB_OUTPUT_DIR)
    end
  end

  # Generate RSS feed
  posts_xml = rss_posts.sort_by { |post| post[:date] }.reverse.map do |post|
    """
    <item>
      <title>#{post[:title]}</title>
      <link>#{post[:url]}</link>
      <pubDate>#{post[:date].rfc2822}</pubDate>
      <description><![CDATA[#{post[:body]}]]></description>
    </item>
    """
  end


  rss = """<?xml version=\"1.0\" encoding=\"UTF-8\" ?>
  <rss version=\"2.0\">
    <channel>
      <title>#{SITE_TITLE}</title>
      <link>#{WEB_HOST}</link>
      <description>#{SITE_TITLE}</description>
      <language>en-us</language>
      <pubDate>#{Time.now.rfc2822}</pubDate>
      <lastBuildDate>#{Time.now.rfc2822}</lastBuildDate>
      #{posts_xml.join("\n")}
    </channel>
  </rss>
  """

  rss_path = WEB_OUTPUT_DIR + "/rss.xml"
  File.write(rss_path, rss)

  count
end

def build_gemini_capsule
  count = 0
  # Apply gemini/_layout.gmi to all files in /content
  FileUtils.rm_rf(GEMINI_OUTPUT_DIR)

  Dir.glob("#{CONTENT_INPUT_DIR}/**/*").each do |file|
    layout = File.read(GEMINI_INPUT_DIR + "/_layout.gmi")

    if File.file?(file)
      if file.end_with?(".gmi")
        gemtext = File.read(file)
        filtered_gemtext = preprocess_gemtext(gemtext, :gemini)
        
        web_url = WEB_HOST + file.gsub(CONTENT_INPUT_DIR, "").gsub(".gmi", ".html").gsub("/index.html", "/")
        rendered = render_template(layout, content: filtered_gemtext, web_url: web_url)

        gemini_path = file.gsub(CONTENT_INPUT_DIR, GEMINI_OUTPUT_DIR)
        dir = File.dirname(gemini_path)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        File.write(gemini_path, rendered)
        count += 1
      else
        count += copy_file(file, CONTENT_INPUT_DIR, GEMINI_OUTPUT_DIR)
      end
    end
  end

  count
end

if $PROGRAM_NAME == __FILE__
  count = build_web_site
  puts "Generated Web site with #{count} files"

  count = build_gemini_capsule
  puts "Generated Gemini site with #{count} files"

  if ARGV[0] == 'server'
    Signal.trap("INT") { exit }

    # Start a file system watcher to regenerate the site on changes (fork)
    Process.fork do
      Signal.trap("INT") { exit }
      system("fswatch -o #{CONTENT_INPUT_DIR} #{WEB_INPUT_DIR} | xargs -n1 -I{} ruby generate.rb")
    end

    # Start agate server in gemini folder
    Process.fork do
      Signal.trap("INT") { exit }
      system("agate --hostname localhost --content #{GEMINI_OUTPUT_DIR}")
    end
    
    # Start web server in html folder
    system("ruby -run -e httpd _site -p 8000")
  end
end