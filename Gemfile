source 'https://rubygems.org'

gemspec

gem 'rake'
gem 'racc', '1.8.1'
gem 'kpeg', '>= 1.3.3'
gem 'test-unit'
gem 'test-unit-ruby-core'
gem 'rubocop', '>= 1.31.0'
gem 'gettext'
gem 'webrick'

if ENV['PRISM_VERSION'] == 'head'
  gem 'prism', github: 'ruby/prism'
elsif ENV['PRISM_VERSION']
  gem 'prism', ENV['PRISM_VERSION']
end

platforms :ruby do
  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.2')
    gem 'mini_racer' # For testing the searcher.js file
  end
end
