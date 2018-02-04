lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'multiprotocol_thrift_rack_app'
  spec.version       = File.read('VERSION').strip
  spec.authors       = ['Dmitrij Fedorenko']
  spec.email         = ['c0va23@gmail.com']

  spec.summary       = 'Multiprotocol Thrift Rack app server'
  spec.description   = 'Ruby HTTP Thrif server with support muptiple ' \
                       'protocols  (JSON, Binary and etc.)'
  spec.homepage      = "https://github.com/c0va23/#{spec.name}"
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rack'
  spec.add_dependency 'thrift', '~> 0.9'

  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52.1'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.22.2'
end
