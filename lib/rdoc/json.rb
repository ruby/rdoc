# A workaround to allow RDoc to work on MacRuby, which has a known incompatibility with the json gem.

module RDoc
  ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
  case ruby_engine
  when 'macruby' then
    begin
      require 'multi_json'
      JSON = MultiJson
    rescue LoadError
      abort 'Unable to load multi_json. MacRuby cannot use json at this time, so please install multi_json by hand.'
    end
  else
    gem 'json'
    require 'json'
    JSON = ::JSON
  end
end