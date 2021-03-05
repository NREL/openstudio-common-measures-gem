lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'openstudio/common_measures/version'

Gem::Specification.new do |spec|
  spec.name          = 'openstudio-common-measures'
  spec.version       = OpenStudio::CommonMeasures::VERSION
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['David Goldwasser', 'Nicholas Long']
  spec.email         = ['david.goldwasser@nrel.gov', 'nicholas.long@nrel.gov']

  spec.homepage      = 'https://openstudio.net'
  spec.summary       = 'Common library and measures for OpenStudio'
  spec.description   = 'Common library and measures for OpenStudio'
  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/NREL/openstudio-common-measures-gem/issues',
    'changelog_uri' => 'https://github.com/NREL/openstudio-common-measures-gem/blob/develop/CHANGELOG.md',
    # 'documentation_uri' =>  'https://www.rubydoc.info/gems/openstudio-common-measures-gem/#{gem.version}',
    'source_code_uri' => "https://github.com/NREL/openstudio-common-measures-gem/tree/v#{spec.version}"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|lib.measures.*tests|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.7.0'

  spec.add_dependency 'bundler', '>= 2.1'
  spec.add_dependency 'openstudio-extension', '~> 0.4.0'
  spec.add_dependency 'openstudio-standards', '~> 0.2.12'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
end
