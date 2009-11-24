require 'rdoc/code_objects'
require 'fileutils'

class RDoc::RI::Store

  attr_reader :cache
  attr_reader :path

  def initialize path
    @path = path

    @cache = {
      :class_methods => {},
      :instance_methods => {},
      :modules => [],
      :ancestors => {},
    }
  end

  def cache_path
    File.join @path, 'cache.ri'
  end

  def class_file klass_name
    name = klass_name.split('::').last
    File.join class_path(klass_name), "cdesc-#{name}.ri"
  end

  def class_methods
    @cache[:class_methods]
  end

  def class_path klass_name
    File.join @path, *klass_name.split('::')
  end

  def instance_methods
    @cache[:instance_methods]
  end

  def load_cache
    open cache_path, 'rb' do |io|
      @cache = Marshal.load io.read
    end
  rescue Errno::ENOENT
  end

  def load_class klass_name
    open class_file(klass_name), 'rb' do |io|
      Marshal.load io.read
    end
  end

  def load_method klass_name, method_name
    open method_file(klass_name, method_name), 'rb' do |io|
      Marshal.load io.read
    end
  end

  def method_file klass_name, method_name
    method_name = method_name.split('::').last
    method_name =~ /#(.*)/
    method_type = $1 ? 'i' : 'c'
    method_name = $1 if $1

    method_name = if ''.respond_to? :ord then
                    method_name.gsub(/\W/) { "%%%02x" % $&[0].ord }
                  else
                    method_name.gsub(/\W/) { "%%%02x" % $&[0] }
                  end

    File.join class_path(klass_name), "#{method_name}-#{method_type}.ri"
  end

  def save_cache
    open cache_path, 'wb' do |io|
      Marshal.dump @cache, io
    end
  end

  def save_class klass
    FileUtils.mkdir_p class_path(klass.full_name)

    @cache[:modules] << klass.full_name

    path = class_file klass.full_name

    begin
      disk_klass = nil

      open path, 'rb' do |io|
        disk_klass = Marshal.load io.read
      end

      klass.merge disk_klass
    rescue Errno::ENOENT
    end

    ancestors = klass.ancestors.map do |ancestor|
      # HACK for classes we don't know about (class X < RuntimeError)
      String === ancestor ? ancestor : ancestor.full_name
    end

    @cache[:ancestors][klass.full_name] ||= []
    @cache[:ancestors][klass.full_name].push(*ancestors)

    open path, 'wb' do |io|
      Marshal.dump klass, io
    end
  end

  def save_method klass, method
    FileUtils.mkdir_p class_path(klass.full_name)

    cache = if method.singleton then
              @cache[:class_methods]
            else
              @cache[:instance_methods]
            end
    cache[klass.full_name] ||= []
    cache[klass.full_name] << method.name

    open method_file(klass.full_name, method.full_name), 'wb' do |io|
      Marshal.dump method, io
    end
  end

end

