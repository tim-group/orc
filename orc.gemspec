require 'rake'
hash = `cat ".git/$(cat .git/HEAD | cut -d' ' -f2)" | head -c 7`
v_part = ENV['BUILD_NUMBER'] || "0.pre.#{hash}" # 0.pre to make debian consider any pre-release cut from git
                                                 # version of the package to be _older_ than the last CI build.
version = "0.0.#{v_part}"

Gem::Specification.new do |s|
  s.name        = 'orc'
  s.version     = version
  s.date        = '2012-11-03'
  s.summary     = "Orc orchestration tool"
  s.description = "Orc is a model driven deployment tool, written in ruby, for deploying applications"
  s.authors     = ["David Ellis", "Tomas Doran"]
  s.email       = 'infra@timgroup.com'
  s.files       = FileList['lib/**/*.rb',
                            'bin/*',
                            ].to_a
  s.add_dependency('git', '>= 1.2.5')
  s.add_development_dependency('rspec')
  s.add_development_dependency('ci_reporter')
  s.add_development_dependency('rake')
end
