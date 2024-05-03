#! /usr/bin/env ruby

require "fileutils"

def lex_gemtext(gemtext)
  in_pre = false

  gemtext.split("\n").map do |line|
    if line.start_with?("```")
      in_pre = !in_pre
      { type: :pre_div }
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
        { type: :link, url: url, text: words[1..].join(" ")}
      end
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
    when :pre_div
      closing_pre = tokens[i+1..].index { |t| t[:type] == :pre_div }
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

    else
      "<p>#{safe_text}</p>"
    end
  end.join("\n")
end

def gemtext2tokens(gemtext)
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

GEMINI_INPUT_DIR = 'gemini'
WEB_INPUT_DIR = 'web'
SITE_OUTPUT_DIR = '_site'
LAYOUT_PATH = WEB_INPUT_DIR + "/_layout.html"
GEMINI_HOST = 'gemini://gemini.rockwellschrock.com/'
SITE_TITLE = 'Rockwell Schrock'

def process_site(path)
  count = 0
  FileUtils.rm_rf(SITE_OUTPUT_DIR)

  # Recursively process all files in the /content directory and output to /html
  Dir.glob("#{path}/**/*").each do |file|
    if File.file?(file)
      if file.end_with?(".gmi")
        gemtext = File.read(file)
        tokens = gemtext2tokens(gemtext)
        title = find_first_heading(tokens).dup
        title << " - #{SITE_TITLE}" unless title == SITE_TITLE
        
        gemini_url = GEMINI_HOST + file.gsub(GEMINI_INPUT_DIR, "")
        layout = File.read(LAYOUT_PATH)
        html = render_template(layout, { title: title, content: render_html(tokens), gemini_url: gemini_url})

        html_path = file.gsub(GEMINI_INPUT_DIR, SITE_OUTPUT_DIR).gsub(".gmi", ".html")
        dir = File.dirname(html_path)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        File.write(html_path, html)
        count += 1
      else
        out_file = file.gsub(GEMINI_INPUT_DIR, SITE_OUTPUT_DIR)
        dir = File.dirname(out_file)
        FileUtils.mkdir_p(dir) unless File.directory?(dir)
        FileUtils.cp(file, out_file)
        count += 1
      end
    end
  end

  # Copy everything from /web to /_site, except if the file starts with an underscore
  Dir.glob("#{WEB_INPUT_DIR}/**/*").each do |file|
    if File.file?(file)
      out_file = file.gsub(WEB_INPUT_DIR, SITE_OUTPUT_DIR)
      dir = File.dirname(out_file)
      FileUtils.mkdir_p(dir) unless File.directory?(dir)
      FileUtils.cp(file, out_file)
      count += 1
    end
  end

  count
end

if $PROGRAM_NAME == __FILE__
  count = process_site(GEMINI_INPUT_DIR)
  puts "Generated #{count} files"

  if ARGV[0] == 'server'
    Signal.trap("INT") { exit }

    # Start a file system watcher to regenerate the site on changes (fork)
    Process.fork do
      Signal.trap("INT") { exit }
      system("fswatch -o #{GEMINI_INPUT_DIR} #{WEB_INPUT_DIR} | xargs -n1 -I{} ruby generate.rb")
    end
    
    # Start web server in html folder
    system("ruby -run -e httpd _site -p 8000")

  end
end