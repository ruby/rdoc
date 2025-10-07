# frozen_string_literal: true

$:.unshift File.expand_path('lib', __dir__) # default template dir

require_relative 'lib/rdoc/task'
require 'bundler/gem_tasks'
require 'rake/testtask'

begin
  require 'rubocop/rake_task'
rescue LoadError
  puts "RuboCop is not installed"
end

task :test    => [:normal_test, :rubygems_test]

PARSER_FILES = %w[
  lib/rdoc/rd/block_parser.ry
  lib/rdoc/rd/inline_parser.ry
  lib/rdoc/markdown.kpeg
  lib/rdoc/markdown/literals.kpeg
]

$rdoc_rakefile = true

task :default => :test

task rdoc: :generate
RDoc::Task.new do |doc|
  # RDoc task defaults to /html and overrides the op_dir option in .rdoc_options
  doc.rdoc_dir = "_site" # for GitHub Pages
end

task "coverage" do
  cov = []
  e = IO.popen([FileUtils::RUBY, "-I./lib", "exe/rdoc", "-C"], &:read)
  e.scan(/^ *# in file (?<loc>.*)\n *(?<code>.*)|^ *(?<code>.*\S) *# in file (?<loc>.*)/) do
    cov << "%s: %s\n" % $~.values_at(:loc, :code)
  end
  cov.sort!
  puts cov
end

Rake::TestTask.new(:normal_test) do |t|
  t.verbose = true
  t.test_files = FileList["test/**/*_test.rb"].exclude("test/rdoc/rdoc_rubygems_hook_test.rb")
end

Rake::TestTask.new(:rubygems_test) do |t|
  t.verbose = true
  t.pattern = "test/rdoc/rdoc_rubygems_hook_test.rb"
end

def generate_parser_file(parser_file)
  ext = File.extname(parser_file)
  parsed_file = "#{parser_file.chomp(ext)}.rb"

  puts "Generating #{parsed_file}..."
  case ext
  when '.ry' # need racc
    sh "bundle", "exec", "racc", "-l", "-E", "-o", parsed_file, parser_file
    File.open(parsed_file, 'r+') do |f|
      newtext = "# frozen_string_literal: true\n#{f.read}"
      f.rewind
      f.write newtext
    end
  when '.kpeg' # need kpeg
    sh "bundle", "exec", "kpeg", "-fsv", "-o", parsed_file, parser_file
    File.write(parsed_file, File.read(parsed_file).gsub(/ +$/, '')) # remove trailing spaces
  end

  parsed_file
end

desc "Generate all files used racc and kpeg"
task :generate do
  generated_files = PARSER_FILES.map { |f| generate_parser_file(f) }

  # Run RuboCop autocorrect on generated files
  require 'rubocop'
  cli = RuboCop::CLI.new
  cli.run([
    "--config=.generated_files_rubocop.yml",
    "--autocorrect",
    *generated_files
  ])
end

desc "Verify that generated parser files are up to date"
# Note: This task generates files to verify changes in the parser files.
# So the result is not deterministic with multiple runs.
# We can improve this by using a temporary directory and checking the diff but it's more complex to maintain.
task :verify_generated do
  parsed_files = PARSER_FILES.map { |f| f.sub(/\.(ry|kpeg)\z/, '.rb') }

  # Save current state of generated files
  original_content = {}
  parsed_files.each do |file|
    original_content[file] = File.read(file)
  end

  # Generate files from current source
  Rake::Task[:generate].invoke

  # Check if any files changed
  changed_files = []
  parsed_files.each do |file|
    unless File.exist?(file)
      abort "Generated file #{file} does not exist!"
    end

    new_content = File.read(file)
    if original_content[file] != new_content
      changed_files << file
    end
  end

  if changed_files.empty?
    puts "Generated parser files are up to date."
  else
    puts "Generated parser files are out of date!"
    puts "Please run 'rake generate' to update the files."
    puts
    puts "Files that are out of date:"
    changed_files.each { |f| puts "  - #{f}" }
    exit 1
  end
end

task :clean do
  PARSER_FILES.each do |parser_file|
    parsed_file = parser_file.sub(/\.(ry|kpeg)\z/, '.rb')
    File.delete(parsed_file) if File.exist?(parsed_file)
  end
end

desc "Build #{Bundler::GemHelper.gemspec.full_name} and move it to local ruby/ruby project's bundled gems folder"
namespace :build do
  task local_ruby: :build do
    target = File.join("..", "ruby", "gems")

    unless File.directory?(target)
      abort("Expected Ruby to be cloned under the same parent directory as RDoc to use this task")
    end

    mv("pkg/#{Bundler::GemHelper.gemspec.full_name}.gem", target)
  end
end
