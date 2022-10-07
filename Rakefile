# frozen_string_literal: true

$:.unshift File.expand_path('lib', __dir__) # default template dir

require_relative 'lib/rdoc/task'
require 'bundler/gem_tasks'
require 'rake/testtask'

task :docs    => :generate
task :test    => [:normal_test, :rubygems_test]

PARSER_FILES = %w[
  lib/rdoc/rd/block_parser.ry
  lib/rdoc/rd/inline_parser.ry
  lib/rdoc/markdown.kpeg
  lib/rdoc/markdown/literals.kpeg
]

$rdoc_rakefile = true

task :default => :test

RDoc::Task.new do |doc|
  doc.main = 'README.rdoc'
  doc.title = "rdoc #{RDoc::VERSION} Documentation"
  doc.rdoc_dir = 'html'
  doc.rdoc_files = FileList.new %w[lib/**/*.rb *.rdoc doc/rdoc/markup_reference.rb] - PARSER_FILES
end

task :ghpages do
  docd  = ENV["RDOC_DOCUMENTED_BRANCH"] || "master"
  pages = ENV["RDOC_PAGES_BRANCH"]      || "gh-pages"

  version = IO.popen(%w[git describe] << docd, &:read).chomp \
    and $?.success? && !version.empty? \
    or abort "ERROR: could not discover version."

  `git status --porcelain`.empty? or abort "ERROR: Working copy must be clean."

  when_writing "Updating #{pages} branch to match #{docd} => #{version}" do
    system(*%w[git switch], pages)      or abort "ERROR: switching to #{pages}"
    system(*%w[git reset --hard], docd) or abort "ERROR: setting #{pages} == #{docd}"
    system(*%w[git reset --soft @{u}])  or abort "ERROR: setting #{pages} => upstream"
  end

  when_writing "Updating #{pages} branch with documentation from #{docd}" do
    # running inside another rake process, in case something important has
    # changed between the invocation branch and the documented branch.
    Bundler.with_original_env do
      system("bundle install || bundle update kpeg") or abort "ERROR: bundler failed"
      system(*%w[bundle exec rake])        or warn "warning: build failed"
      system(*%w[bundle exec rake rerdoc]) or abort "ERROR: rdoc generation failed"
    end
    # github pages wants either / (root) or /docs.  "rm -rf docs" is safer.
    rm_rf "docs"
    mv    "html", "docs"
    touch "docs/.nojekyll" # => skips default pages action build step
    system(*%w[git add --force --all docs]) or abort "ERROR: adding docs to git"
  end

  when_writing "Committing #{pages} changes for #{version}" do
    commit_msg = "Generated rdoc html for #{version}"
    system(*%w[git commit -m], commit_msg)  or abort "ERROR: committing #{pages}"

    puts "*** Latest changes committed.  Deploy with 'git push origin HEAD'"
  end
end

Rake::TestTask.new(:normal_test) do |t|
  t.libs = []
  t.verbose = true
  t.deps = :generate
  t.test_files = FileList["test/**/test_*.rb"].exclude("test/rdoc/test_rdoc_rubygems_hook.rb")
end

Rake::TestTask.new(:rubygems_test) do |t|
  t.libs = []
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
      ruby "#{racc} -l -o #{rb_file} #{parser_file}"
      open(rb_file, 'r+') do |f|
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
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = [*parsed_files]
  end
  task :build => [:generate, "rubocop:auto_correct"]
end
