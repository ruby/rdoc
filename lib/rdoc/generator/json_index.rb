require 'json'

##
# The JsonIndex generator is designed to complement an HTML generator and
# produces a JSON search index.  This generator is derived from sdoc by
# Vladimir Kolesnikov and contains verbatim code written by him.
#
# This generator is designed to be used with a regular HTML generator:
#
#   class RDoc::Generator::Darkfish
#     def initialize options
#       # ...
#       @base_dir = Pathname.pwd.expand_path
#
#       @json_index = RDoc::Generator::JsonIndex.new self, options
#     end
#
#     def generate top_levels
#       # ...
#       @json_index.generate top_levels
#     end
#   end
#
# == LICENSE
#
# Copyright (c) 2009 Vladimir Kolesnikov
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class RDoc::Generator::JsonIndex

  include RDoc::Text

  ##
  # Where the search index lives in the generated output

  SEARCH_INDEX_FILE = File.join 'js', 'search_index.js'

  attr_reader :index # :nodoc:

  ##
  # Creates a new generator.  +parent_generator+ is used to determine the
  # class_dir and file_dir of links in the output index.
  #
  # +options+ are the same options passed to the parent generator.

  def initialize parent_generator, options
    @parent_generator = parent_generator
    @options = options

    @template_dir = Pathname.new options.template_dir
    @base_dir = @parent_generator.base_dir

    @classes = nil
    @files   = nil
    @index   = nil
  end

  ##
  # Output progress information if debugging is enabled

  def debug_msg *msg
    return unless $DEBUG_RDOC
    $stderr.puts(*msg)
  end

  ##
  # Creates the JSON index.

  def generate top_levels
    debug_msg "Generating JSON index"

    reset top_levels.sort, RDoc::TopLevel.all_classes_and_modules.sort

    index_classes
    index_methods
    index_pages

    @index[:searchIndex].uniq!
    @index[:longSearchIndex].uniq!

    debug_msg "  writing search index to %s" % SEARCH_INDEX_FILE
    data = { :index => @index }

    out_file = @base_dir + @options.op_dir + SEARCH_INDEX_FILE

    options = { :verbose => $DEBUG_RDOC, :noop => @options.dry_run }
    FileUtils.mkdir_p out_file.dirname, options

    out_file.open 'w', 0644 do |io| # TODO utf-8
      io.write 'var search_data = '

      JSON.dump data, io, 0
    end unless @options.dry_run
  end

  ##
  # Adds classes and modules to the index

  def index_classes
    debug_msg "  generating class search index"

    documented = @classes.uniq.select do |klass|
      klass.document_self_or_methods
    end

    documented.each do |klass|
      debug_msg "    #{klass.parent.full_name}::#{klass.name}"
      @index[:searchIndex]     << search_string(klass.name)
      @index[:longSearchIndex] << search_string(klass.parent.full_name)
      @index[:info]            << klass.search_record
    end
  end

  ##
  # Adds methods to the index

  def index_methods
    debug_msg "  generating method search index"

    list = @classes.uniq.map do |klass|
      klass.method_list
    end.flatten.sort_by do |method|
      [method.name, method.parent.full_name]
    end

    list.each do |method|
      debug_msg "    #{method.full_name}"
      @index[:searchIndex]     << "#{search_string method.name}()"
      @index[:longSearchIndex] << search_string(method.parent.full_name)
      @index[:info]            << method.search_record
    end
  end

  ##
  # Adds pages to the index

  def index_pages
    debug_msg "  generating pages search index"

    pages = @files.select do |file|
      file.text?
    end

    pages.each do |page|
      debug_msg "    #{page.path}"
      @index[:searchIndex]     << search_string(page.name)
      @index[:longSearchIndex] << search_string(page.path)
      @index[:info]            << page.search_record
    end
  end

  ##
  # The directory classes are written to

  def class_dir
    @parent_generator.class_dir
  end

  ##
  # The directory files are written to

  def file_dir
    @parent_generator.file_dir
  end

  def reset files, classes # :nodoc:
    @files   = files
    @classes = classes

    @index = {
      :searchIndex => [],
      :longSearchIndex => [],
      :info => []
    }
  end

  ##
  # Removes whitespace and downcases +string+

  def search_string string
    string.downcase.gsub(/\s/, '')
  end

end

