require 'fileutils'
require 'open3'
require 'test/unit'
require 'tmpdir'

class IntegrationTestCase < Test::Unit::TestCase

  # Run rdoc with the given markup as input; suffix is used for temp dirname uniqueness.
  def run_rdoc(markup, suffix = nil)
    # Default suffix is the name of the calling test, extracted from caller array.
    suffix ||= caller[0].split('#').last.chop
    # Make the temp dirpath.
    filestem = suffix.to_s
    tmpdirpath = File.join(Dir.tmpdir, 'MarkupTest-' + filestem)
    # Remove the dir and re-create it (belt and suspenders).
    FileUtils.rm_rf(tmpdirpath)
    Dir.mkdir(tmpdirpath)
    FileUtils.chmod(0700, tmpdirpath)
    # Do all the work in the temporary directory.
    Dir.chdir(tmpdirpath) do
      # Create the markdown file.
      rdoc_filename = filestem + '.rdoc'
      File.write(rdoc_filename, markup)
      # Run rdoc, to create the HTML file.
      command = "rdoc #{rdoc_filename + 'xxx'}"
      Open3.popen3(command) do |_, stdout, stderr|
        stdout_s = stdout.read
        raise RuntimeError.new(stdout_s) unless stdout_s.match('Parsing')
        stderr_s = stderr.read
        raise RuntimeError.new(stderr_s) unless stderr_s.match('Generating')
      end
      # Get the HTML as lines.
      html_filename = filestem + '_rdoc.html'
      html_filepath = File.join('doc', html_filename)
      html_lines = File.readlines(html_filepath)
      # Yield them.
      yield html_lines
    end
    # Clean up.
    FileUtils.rm_rf(tmpdirpath)
  end

  # Convenience method for selecting lines.
  def select_lines(lines, pattern)
    lines.select {|line| line.match(pattern) }
  end

end
