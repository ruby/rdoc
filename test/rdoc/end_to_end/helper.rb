require 'fileutils'
require_relative '../xref_test_case'

class Helper

  # Create temporary directory.
  def self.setup(filestem)
    @dirpath = File.join(Dir.tmpdir, 'MarkupTest-' + filestem)
    FileUtils.rm_rf(@dirpath)
    Dir.mkdir(@dirpath)
    FileUtils.chmod(0700, @dirpath)
  end

  # Remove temporary directory.
  def self.teardown
    FileUtils.rm_rf(@dirpath)
  end

  # Convenience method for selecting lines.
  def self.select_lines(lines, pattern)
    lines.select { |line| line.match(pattern) }
  end

  # Run rdoc for given markup; method is used in setup.
  def self.run_rdoc(markup, method)

    filestem = method.to_s
    self.setup(filestem)

    # Create the markdown file.
    rdoc_filename = filestem + '.rdoc'
    rdoc_filepath = File.join(@dirpath, rdoc_filename)
    File.write(rdoc_filepath, markup)

    # Run rdoc, to create the HTML file.
    Dir.chdir(@dirpath) do
      `rdoc #{rdoc_filepath}`
    end

    # Get the HTML as lines.
    html_filename = filestem + '_rdoc.html'
    html_filepath = File.join(@dirpath, 'doc', html_filename)
    html_lines = File.readlines(html_filepath)

    yield html_lines

    self.teardown

  end


end
