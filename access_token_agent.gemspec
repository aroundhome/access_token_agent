lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'access_token_agent/version'

Gem::Specification.new do |s|
  s.name        = 'access_token_agent'
  s.version     = AccessTokenAgent::VERSION
  s.date        = '2020-10-02'
  s.summary     = 'Handles authentication against an OAuth2 provider'
  s.homepage    = 'https://github.com/aroundhome/access_token_agent'
  s.description = 'Retrieves an access token from an OAuth2 provider ' \
                  'using the supplied credentials.'
  s.authors     = ['be Around GmbH']
  s.email       = 'oss@aroundhome.de'
  s.license     = 'MIT'
  s.files       = `git ls-files -z`.split("\x0")
                                   .reject { |f| f.match(%r{^spec/}) }

  s.required_ruby_version = '>= 3.4'

  s.add_development_dependency 'bundler', '> 1.11', '< 3'
  s.add_development_dependency 'pry', '~> 0.10'
  s.add_development_dependency 'rspec', '~> 3.4'
  s.add_development_dependency 'rubocop', '~> 1.75'
  s.add_development_dependency 'rubocop-performance', '~> 1.25'
  s.add_development_dependency 'simplecov', '~> 0.16'
  s.add_development_dependency 'vcr', '~> 6.3'
  s.add_development_dependency 'webmock', '~> 3'
end
