# -*- encoding: utf-8 -*-
require File.expand_path('../lib/multiparameter_date_time/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Case Commons, LLC", "Grant Hutchins", "Trace Wax"]
  gem.email         = ["casecommons-dev@googlegroups.com", "gems@nertzy.com", "gems@tracedwax.com"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = "https://github.com/Casecommons/multiparameter_date_time"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "multiparameter_date_time"
  gem.require_paths = ["lib"]
  gem.version       = MultiparameterDateTime::VERSION
end
