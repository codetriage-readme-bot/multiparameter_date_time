# -*- encoding: utf-8 -*-
require File.expand_path('../lib/multiparameter_date_time/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Case Commons, LLC', 'Grant Hutchins', 'Trace Wax', 'Jason Berlinsky']
  gem.email         = ['casecommons-dev@googlegroups.com', 'gems@nertzy.com', 'gems@tracedwax.com', 'jason@jasonberlinsky.com']
  gem.summary       = 'Set a DateTime via two accessors, one for the date, one for the time'
  gem.homepage      = 'https://github.com/Casecommons/multiparameter_date_time'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'multiparameter_date_time'
  gem.require_paths = ['lib']
  gem.version       = MultiparameterDateTime::VERSION
  gem.licenses      = 'MIT'

  gem.required_ruby_version = '>= 1.9.2'

  gem.add_dependency 'american_date'

  gem.add_development_dependency 'activerecord'
  gem.add_development_dependency 'activesupport'
  gem.add_development_dependency 'rspec', '~> 2.11'
  gem.add_development_dependency 'with_model', "~> 0.3"
  gem.add_development_dependency 'informal', "~> 0.1.0"
end
