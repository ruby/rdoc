# frozen_string_literal: true
require 'rbconfig'
require 'find'
require 'cgi'

require_relative '../rdoc'

# A class to display Ruby HTML documentation.
class RDoc::WebRI

  def initialize(target_name, options)
    ruby_exe_filepath = RbConfig.ruby
    ruby_installation_dirpath = File.dirname(File.dirname(ruby_exe_filepath))
    ri_filepaths = get_ri_filepaths(ruby_installation_dirpath)
    html_filepaths = get_html_filepaths(ruby_installation_dirpath)
    target_urls = {}
    missing_html = []
    unused_ri = []
    ri_filepaths.each do |ri_filepath|
      next if ri_filepath == 'cache.ri'
      filepath = ri_filepath.sub('.ri', '.html')
      name, target_url = case
                      when filepath.match(/-c\.html/) # Class method.
                        dirname = File.dirname(filepath)
                        method_name = CGI.unescape(File.basename(filepath).sub('-c.html', ''))
                        target_url = dirname + '.html#method-c-' + method_name
                        name = dirname.gsub('/', '::') + '::' + method_name
                        [name, target_url]
                      when filepath.match(/-i\.html/) # Instance method.
                        dirname = File.dirname(filepath)
                        method_name = CGI.unescape(File.basename(filepath).sub('-i.html', ''))
                        target_url = dirname + '.html#method-i-' + method_name
                        name = dirname.gsub('/', '::') + '#' + method_name
                        [name, target_url]
                      when filepath.match(/\/cdesc-/) # Class.
                        target_url = File.dirname(filepath) + '.html'
                        name = target_url.gsub('/', '::').sub('.html', '')
                        [name, target_url]
                      when File.basename(filepath).match(/^page-/)
                        target_url = filepath.sub('page-', '') # File.
                        name = target_url.sub('.html', '').sub(/_rdoc$/, '.rdoc').sub(/_md$/, '.md')
                        [name, target_url]
                      else
                        raise filepath
                      end
      unless html_filepaths.include?(target_url)
        missing_html.push(target_url)
        unused_ri.push(ri_filepath)
      end
      target_urls[name] = target_url
    end
    # puts missing_html.uniq
    # puts unused_ri

    selected_urls = {}
    target_urls.select do |name, value|
      if name.match(Regexp.new(target_name))
        selected_urls[name] = value
      end
    end
    case selected_urls.size
    when 0
      puts "No documentation found for #{target_name}."
    when 1
      url = selected_urls.first[1]
      open_url(url)
    else
      p get_choice(selected_urls.keys)
    end
  end

def get_ri_filepaths(ruby_installation_dirpath)
  # Directory containing filetree of .ri files installed by RI.
  ri_dirpath = File.join(ruby_installation_dirpath, 'share', 'ri', RUBY_ENGINE_VERSION, 'system')
  ri_filepaths = []
  Find.find(ri_dirpath).each do |path|
    next unless path.end_with?('.ri')
    path.sub!(ri_dirpath + '/', '')
    ri_filepaths.push(path)
  end
  ri_filepaths
  end

  def get_html_filepaths(ruby_installation_dirpath)
    # Directory containing filetree of .html files installed by RI.
    html_dirpath = File.join(ruby_installation_dirpath, *%w[share doc ruby html])
    filepaths = []
    Find.find(html_dirpath).each do |path|
      next unless path.end_with?('.html')
      path.sub!(html_dirpath + '/', '')
      filepaths.push(path)
    end
    filepaths
  end

  def get_choice(choices)
    choices[get_choice_index(choices)]
  end

  def get_choice_index(choices)
    index = nil
    range = (0..choices.size - 1)
    until range.include?(index)
      choices.each_with_index do |choice, i|
        s = "%6d" % i
        puts "  #{s}:  #{choice}"
      end
      print "Choose (#{range}):  "
      $stdout.flush
      response = gets
      index = response.match(/\d+/) ? response.to_i : -1
    end
    index
  end

  def open_url(target_url)
    host_os = RbConfig::CONFIG['host_os']
    executable_name = case host_os
                      when /linux|bsd/
                        'xdg-open'
                      when /darwin/
                        'open'
                      when /32$/
                        'start'
                      else
                        message = "Unrecognized host OS: '#{host_os}'."
                        raise RuntimeError.new(message)
                      end
    command = "#{executable_name} #{target_url}"
    p command
    return
    system(command)
    end

end
