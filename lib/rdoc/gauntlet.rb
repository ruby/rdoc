require 'rdoc/rdoc'
require 'gauntlet'
require 'tmpdir'
require 'fileutils'

class RDoc::Gauntlet < Gauntlet

  def run name
    tmpdir = Dir.mktmpdir name
    yaml = File.read 'gemspec'
    spec = Gem::Specification.from_yaml yaml

    args = %W[--ri --quiet --op #{tmpdir}/ri]
    args.push(*spec.rdoc_options)
    args << spec.require_paths
    args << spec.extra_rdoc_files
    args = args.flatten.map { |a| a.to_s }

    puts "#{name} - rdoc #{args.join ' '}"

    self.dirty = true
    r = RDoc::RDoc.new

    begin
      r.document args
      self.data[name] = [args]
      puts 'passed'
    rescue RDoc::Error => e
      puts "failed - (#{e.class}) #{e.message}"
      self.data[name] = [args, e.class, e.message, e.backtrace]
    end
  rescue Gem::Exception
    puts "bad gem #{name}"
    FileUtils.rm_rf File.expand_path "~/.gauntlet/#{name}.tgz"
  ensure
    puts
    FileUtils.rm_rf tmpdir
  end

end

RDoc::Gauntlet.new.run_the_gauntlet if $0 == __FILE__

