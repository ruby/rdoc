require 'fileutils'
require 'open3'
require_relative '../xref_test_case'

class Helper

  # Convenience method for selecting lines.
  def self.select_lines(lines, pattern)
    lines.select { |line| line.match(pattern) }
  end

  # Run rdoc for given markup; method is the caller's __method__, used for filename uniqueness.
  def self.run_rdoc(markup, method)
    # Make the temp dirpath; remove the dir and re-create it.
    filestem = method.to_s
    tmpdirpath = File.join(Dir.tmpdir, 'MarkupTest-' + filestem)
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
      puts command
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


end
