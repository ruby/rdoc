# frozen_string_literal: true
require 'open-uri'
require 'nokogiri'
include Nokogiri

require_relative '../rdoc'

# A class to display Ruby HTML documentation.
class RDoc::WebRI

  # Where the documentation lives.
  ReleasesUrl = 'https://docs.ruby-lang.org/en/'


  def initialize(target_name, options)
    release_name = get_release_name(options[:release])
    entries = get_entries(release_name)
    target_entries = entries[target_name]
    if target_entries.nil? || target_entries.empty?
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

  def get_release_name(requested_release_name)
    if requested_release_name.nil?
      puts "Selecting documentation release based on installed Ruby (#{RUBY_VERSION})."
      requested_release_name = RUBY_VERSION
    end
    available_release_names = []
    html = URI.open(ReleasesUrl)
    @doc = Nokogiri::HTML(html)
    link_eles = @doc.xpath("//a")
    link_eles.each do |link_ele|
      text = link_ele.text
      next if text.match('outdated')
      release_name = text.sub('Ruby ', '')
      available_release_names.push(release_name)
    end
    release_name = nil
    if available_release_names.include?(requested_release_name)
      release_name = requested_release_name
    else
      available_release_names.each do |name|
        if requested_release_name.start_with?(name)
          release_name = name
          break
        end
      end
    end
    if release_name.nil?
      puts "Could not select documentation release '#{requested_release_name}' from #{available_release_names}."
      release_name = get_choice(available_release_names)
    end
    puts "Selected documentation release #{release_name}."
    release_name
  end

  def get_entries(release_name)
    toc_url = File.join(ReleasesUrl, release_name, 'table_of_contents.html')
    html = URI.open(toc_url)
    doc = Nokogiri::HTML(html)
    entries = {}
    %w[file class module method].each do |type|
      add_entries(entries, doc, type)
    end
    entries
  end

  def add_entries(entries, doc, type)
    xpath = "//li[@class='#{type}']"
    li_eles = doc.xpath(xpath)
    li_eles.each do |li_ele|
      a_ele = li_ele.xpath('./a').first
      short_name = a_ele.text
      full_name = if type == 'method'
                    method_span_ele = li_ele.xpath('./span').first
                    class_name = method_span_ele.text
                    class_name + short_name
                  else
                    short_name
                  end
      href = a_ele.attributes['href'].value
      entry = Entry.new(type, full_name, href)
      entries[short_name] ||= []
      entries[short_name].push(entry)
      next unless type == 'method'
      # We want additional entries for full name, bare name, and dot name.
      bare_name = short_name.sub(/^::/, '').sub(/^#/, '')
      dot_name = '.' + bare_name
      [full_name, bare_name, dot_name].each do |other_name|
        entries[other_name] ||= []
        entries[other_name].push(entry)
      end
    end
  end

  def get_target_url(target_entries, release_name)
    target_entry = nil
    if target_entries.size == 1
      target_entry = target_entries.first
    else
      sorted_target_entries = target_entries.sort_by {|entry| entry.full_name}
      full_names = sorted_target_entries.map { |entry| "#{entry.full_name} (#{entry.type})" }
      index = get_choice_index(full_names)
      target_entry = sorted_target_entries[index]
    end
    File.join(ReleasesUrl, release_name, target_entry.href).to_s
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
    system(command)
  end

  def get_choice(choices)
    choices[get_choice_index(choices)]
  end

  def get_choice_index(choices)
    index = nil
    range = (0..choices.size - 1)
    until range.include?(index)
      choices.each_with_index do |choice, i|
        puts "  #{i}:  #{choice}"
      end
      print "Choose (#{range}):  "
      response = gets
      index = response.match(/\d+/) ? response.to_i : -1
    end
    index
  end

end
