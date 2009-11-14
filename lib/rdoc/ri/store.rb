require 'rdoc/code_objects'
require 'fileutils'

class RDoc::RI::Store

  def initialize path 
    @path = path
  end

  def klass_file klass_name
    File.join klass_path(klass_name), "cdesc-#{klass_name}.ri"
  end

  def klass_path klass_name
    File.join @path, klass_name
  end

  def load_class klass_name
    open klass_file(klass_name), 'rb' do |io|
      Marshal.load io.read
    end
  end

  def load_method klass_name, method_name
    open method_file(klass_name, method_name), 'rb' do |io|
      Marshal.load io.read
    end
  end

  def method_file klass_name, method_name
    method_name =~ /([#:])/
    method_type = $1 == '#' ? 'i' : 'c'
    method_name = $'

    method_name = if ''.respond_to? :ord then
                    method_name.gsub(/\W/) { "%%%02x" % $&[0].ord }
                  else
                    method_name.gsub(/\W/) { "%%%02x" % $&[0] }
                  end

    File.join klass_path(klass_name), "#{method_name}-#{method_type}.ri"
  end

  def save_class klass
    FileUtils.mkdir_p klass_path(klass.name)

    open klass_file(klass.name), 'wb' do |io|
      Marshal.dump klass, io
    end
  end

  def save_method klass, method
    FileUtils.mkdir_p klass_path(klass.name)

    open method_file(klass.name, method.full_name), 'wb' do |io|
      Marshal.dump method, io
    end
  end

end

