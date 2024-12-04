# frozen_string_literal: true
require 'rbconfig'
require 'find'

require_relative '../rdoc'

# A class to display Ruby HTML documentation.
class RDoc::WebRI

  def initialize(target_name, options)
    ruby_exe_filepath = RbConfig.ruby
    ruby_installation_dirpath = File.dirname(File.dirname(ruby_exe_filepath))
    ri_filepaths = get_ri_filepaths(ruby_installation_dirpath)
    html_filepaths = get_html_filepaths(ruby_installation_dirpath)
    filepaths = {}
    missing_html = []
    unused_ri = []
    ri_filepaths.each do |ri_filepath|
      next if ri_filepath == 'cache.ri'
      filepath = ri_filepath.sub('.ri', '.html')
      html_filepath = case
                      when filepath.match(/-c\.html/)
                        dirname = File.dirname(filepath)
                        basename = File.basename(filepath)
                        name = basename.sub('-c.html', '')
                        dirname + '.html'
                      when filepath.match(/-i\.html/)
                        dirname = File.dirname(filepath)
                        basename = File.basename(filepath)
                        name = basename.sub('-i.html', '')
                        dirname + '.html'
                      when filepath.match(/\/cdesc-/)
                        File.dirname(filepath) + '.html'
                      when File.basename(filepath).match(/^page-/)
                        filepath.sub('page-', '')
                      else
                        raise filepath
                      end
      unless html_filepaths.include?(html_filepath)
        missing_html.push(html_filepath)
        unused_ri.push(ri_filepath)
      end
      filepaths[ri_filepath] = html_filepath
    end
    # puts missing_html.uniq
    # puts unused_ri

    puts filepaths.keys.sort.take(200)
    puts target_name
    return

    target_entries = []
    entries.select do |name, value|
      if name.match(Regexp.new(target_name))
        value.each do |x|
          target_entries << x
        end
      end
    end
    if target_entries.empty?
      puts "No documentation found for #{target_name}."
    else
      target_url = get_target_url(target_entries, release_name)
      open_url(target_url)
    end
  end

class Entry

    attr_accessor :type, :full_name, :href

    def initialize(type, full_name, href)
      self.type = type
      self.full_name = full_name
      self.href = href
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

end
