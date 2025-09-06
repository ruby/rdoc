require 'fileutils'
require 'rexml/document'
require_relative '../xref_test_case'

include REXML

class Helper

  def self.setup(filestem)
    @dirpath = File.join(Dir.tmpdir, 'MarkupTest-' + filestem)
    FileUtils.rm_rf(@dirpath)
    Dir.mkdir(@dirpath)
  end

  def self.teardown
    FileUtils.rm_rf(@dirpath)
  end

  def self.select_lines(lines, pattern)
    lines.select { |line| line.match(pattern) }
  end

  def self.run_rdoc(method, markup)

    filestem = method.to_s
    self.setup(filestem)

    # Create the markdown file.
    rdoc_filename = filestem + '.rdoc'
    rdoc_filepath = File.join(@dirpath, rdoc_filename)
    File.write(rdoc_filepath, markup)

    # Run rdoc, to create the HTML file.
    Dir.chdir(@dirpath) do
      `rdoc #{rdoc_filepath}`
      # command = "rdoc #{rdoc_filepath}"
      # system(command)
    end

    # Get the HTML as lines.
    html_filename = filestem + '_rdoc.html'
    html_filepath = File.join(@dirpath, 'doc', html_filename)
    html_lines = File.readlines(html_filepath)

    yield html_lines

    self.teardown

  end


end
