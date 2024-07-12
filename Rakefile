# frozen_string_literal: true

$:.unshift File.expand_path('lib', __dir__) # default template dir

require_relative 'lib/rdoc/task'
require 'bundler/gem_tasks'
require 'rake/testtask'

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
  doc.main = 'README.rdoc'
  doc.title = "rdoc #{RDoc::VERSION} Documentation"
  doc.rdoc_dir = '_site' # for github pages
  doc.rdoc_files = FileList.new %w[lib/**/*.rb *.rdoc *.md doc/rdoc/markup_reference.rb] - PARSER_FILES
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
  t.deps = :generate
  t.libs << "test/lib"
  t.ruby_opts << "-rhelper"
  t.test_files = FileList["test/**/test_*.rb"].exclude("test/rdoc/test_rdoc_rubygems_hook.rb")
end

Rake::TestTask.new(:rubygems_test) do |t|
  t.verbose = true
  t.deps = :generate
  t.pattern = "test/rdoc/test_rdoc_rubygems_hook.rb"
end

path = "pkg/#{Bundler::GemHelper.gemspec.full_name}"

package_parser_files = PARSER_FILES.map do |parser_file|
  name = File.basename(parser_file, File.extname(parser_file))
  _path = File.dirname(parser_file)
  package_parser_file = "#{path}/#{name}.rb"
  parsed_file = "#{_path}/#{name}.rb"

  file package_parser_file => parsed_file # ensure copy runs before racc

  package_parser_file
end

parsed_files = PARSER_FILES.map do |parser_file|
  ext = File.extname(parser_file)
  parsed_file = "#{parser_file.chomp(ext)}.rb"

  file parsed_file => parser_file do |t|
    puts "Generating #{parsed_file}..."
    case ext
    when '.ry' # need racc
      racc = Gem.bin_path 'racc', 'racc'
      rb_file = parser_file.gsub(/\.ry\z/, ".rb")
      ruby "#{racc} -l -E -o #{rb_file} #{parser_file}"
      File.open(rb_file, 'r+') do |f|
        newtext = "# frozen_string_literal: true\n#{f.read}"
        f.rewind
        f.write newtext
      end
    when '.kpeg' # need kpeg
      kpeg = Gem.bin_path 'kpeg', 'kpeg'
      rb_file = parser_file.gsub(/\.kpeg\z/, ".rb")
      ruby "#{kpeg} -fsv -o #{rb_file} #{parser_file}"
      File.write(rb_file, File.read(rb_file).gsub(/ +$/, '')) # remove trailing spaces
    end
  end

  parsed_file
end

task "#{path}.gem" => package_parser_files
desc "Generate all files used racc and kpeg"
task :generate => parsed_files

task :clean do
  parsed_files.each do |path|
    File.delete(path) if File.exist?(path)
  end
end

begin
  require 'rubocop/rake_task'
rescue LoadError
else
  RuboCop::RakeTask.new(:format_generated_files) do |t|
    t.options = parsed_files + ["--config=.generated_files_rubocop.yml"]
  end
  task :build => [:generate, "format_generated_files:autocorrect"]
end
