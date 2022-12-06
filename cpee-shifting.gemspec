Gem::Specification.new do |s|
  s.name             = "cpee-shifting"
  s.version          = "1.0.0"
  s.platform         = Gem::Platform::RUBY
  s.license          = "LGPL-3.0"
  s.summary          = "(Lifecycle) manage your process models in a directory or git repo."

  s.description      = "see http://cpee.org"

  s.files            = Dir['{server/*,tools/**/*,lib/**/*,ui/**/*}'] + %w(COPYING Rakefile cpee-shifing.gemspec README.md AUTHORS)
  s.require_path     = 'lib'
  s.extra_rdoc_files = ['README.md']
  s.bindir           = 'tools'
  s.executables      = ['cpee-shifting']

  s.required_ruby_version = '>=2.7.0'

  s.authors          = ['Juergen eTM Mangler']

  s.email            = 'juergen.mangler@gmail.com'
  s.homepage         = 'http://cpee.org/'

  s.add_runtime_dependency 'riddl', '~> 0.99', '>= 0.99.120'
  s.add_runtime_dependency 'weel', '~> 0.99', '>= 0.99.103'
  s.add_runtime_dependency 'json', '~> 2.1'
  s.add_runtime_dependency 'chronic', '~> 0.10', '>= 0.10.2'
  s.add_runtime_dependency 'chronic_duration', '~> 0.10', '>= 0.10.6'
end
