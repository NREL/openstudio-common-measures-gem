lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/common_measures/version'

Gem::Specification.new do |spec|
  spec.name          = 'openstudio-common-measures'
  spec.version       = OpenStudio::CommonMeasures::VERSION
  spec.authors       = ['David Goldwasser', 'Nicholas Long']
  spec.email         = ['david.goldwasser@nrel.gov', 'nicholas.long@nrel.gov']

  spec.summary       = 'Common library and measures for OpenStudio'
  spec.description   = 'Common library and measures for OpenStudio'
  spec.homepage      = 'https://openstudio.net'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|lib.measures.*tests|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'openstudio-extension', '~> 0.1.6'
  spec.add_dependency 'openstudio-standards', '~> 0.2.10'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '12.3.1'
  spec.add_development_dependency 'rspec', '3.7.0'
end
