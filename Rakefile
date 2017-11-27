$:.unshift File.expand_path 'lib'
require 'rdoc/task'
require 'bundler/gem_tasks'
require 'rake/testtask'

task :docs    => :generate
task :test    => :generate

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
  doc.rdoc_files = FileList.new %w[lib/**/*.rb *.rdoc] - PARSER_FILES
end

task ghpages: :rdoc do
  `git checkout gh-pages`
  require "fileutils"
  FileUtils.rm_rf "/tmp/html"
  FileUtils.mv "html", "/tmp"
  FileUtils.rm_rf "*"
  FileUtils.cp_r Dir.glob("/tmp/html/*"), "."
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/test_*.rb']
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
  name = File.basename(parser_file, File.extname(parser_file))
  _path = File.dirname(parser_file)
  parsed_file = "#{_path}/#{name}.rb"

  file parsed_file do |t|
    puts "Generating #{parsed_file}..."
    if parser_file =~ /\.ry\z/ # need racc
      racc = Gem.bin_path 'racc', 'racc'
      rb_file = parser_file.gsub(/\.ry\z/, ".rb")
      ruby "#{racc} -l -o #{rb_file} #{parser_file}"
      open(rb_file, 'r+') do |f|
        newtext = "# frozen_string_literal: true\n#{f.read}"
        f.rewind
        f.write newtext
      end
    elsif parser_file =~ /\.kpeg\z/ # need kpeg
      kpeg = Gem.bin_path 'kpeg', 'kpeg'
      rb_file = parser_file.gsub(/\.kpeg\z/, ".rb")
      ruby "#{kpeg} -fsv -o #{rb_file} #{parser_file}"
    end
  end

  parsed_file
end

task "#{path}.gem" => package_parser_files
task :check_manifest => :generate

desc "Genrate all files used racc and kpeg"
task :generate => parsed_files

# These tasks expect to have the following directory structure:
#
#   git/git.rubini.us/code # Rubinius git HEAD checkout
#   svn/ruby/trunk         # ruby subversion HEAD checkout
#   svn/rdoc/trunk         # RDoc subversion HEAD checkout
#
# If you don't have this directory structure, set RUBY_PATH and/or
# RUBINIUS_PATH.

diff_options = "-urpN --exclude '*svn*' --exclude '*swp' --exclude '*rbc'"
rsync_options = "-avP --exclude '*svn*' --exclude '*swp' --exclude '*rbc' --exclude '*.rej' --exclude '*.orig' --exclude '*.kpeg' --exclude '*.ry' --exclude 'literals_1_8.rb' --exclude 'gauntlet_rdoc.rb'"

rubinius_dir = ENV['RUBINIUS_PATH'] || '../../../git/git.rubini.us/code'
ruby_dir = ENV['RUBY_PATH'] || '../../svn/ruby/trunk'

desc "Updates Ruby HEAD with the currently checked-out copy of RDoc."
task :update_ruby do
  sh "rsync #{rsync_options} bin/rdoc #{ruby_dir}/bin/rdoc"
  sh "rsync #{rsync_options} bin/ri #{ruby_dir}/bin/ri"
  sh "rsync #{rsync_options} lib/ #{ruby_dir}/lib"
  sh "rsync #{rsync_options} test/ #{ruby_dir}/test/rdoc"
end

desc "Diffs Ruby HEAD with the currently checked-out copy of RDoc."
task :diff_ruby do
  sh "diff #{diff_options} bin/rdoc #{ruby_dir}/bin/rdoc; true"
  sh "diff #{diff_options} bin/ri #{ruby_dir}/bin/ri; true"
  sh "diff #{diff_options} lib/rdoc.rb #{ruby_dir}/lib/rdoc.rb; true"
  sh "diff #{diff_options} lib/rdoc #{ruby_dir}/lib/rdoc; true"
  sh "diff #{diff_options} test #{ruby_dir}/test/rdoc; true"
end

desc "Updates Rubinius HEAD with the currently checked-out copy of RDoc."
task :update_rubinius do
  sh "rsync #{rsync_options} bin/rdoc #{rubinius_dir}/lib/bin/rdoc.rb"
  sh "rsync #{rsync_options} bin/ri #{rubinius_dir}/lib/bin/ri.rb"
  sh "rsync #{rsync_options} lib/ #{rubinius_dir}/lib"
  sh "rsync #{rsync_options} test/ #{rubinius_dir}/test/rdoc"
end

desc "Diffs Rubinius HEAD with the currently checked-out copy of RDoc."
task :diff_rubinius do
  sh "diff #{diff_options} bin/rdoc #{rubinius_dir}/lib/bin/rdoc.rb; true"
  sh "diff #{diff_options} bin/ri #{rubinius_dir}/lib/bin/ri.rb; true"
  sh "diff #{diff_options} lib/rdoc.rb #{rubinius_dir}/lib/rdoc.rb; true"
  sh "diff #{diff_options} lib/rdoc #{rubinius_dir}/lib/rdoc; true"
  sh "diff #{diff_options} test #{rubinius_dir}/test/rdoc; true"
end

task :build => [:generate]
