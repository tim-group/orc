hash    = `git rev-parse --short HEAD`.chomp
v_part  = ENV['BUILD_NUMBER'] || "0.pre.#{hash}"
version = "0.1.#{v_part}"

Gem::Specification.new do |s|
  s.name        = 'orc'
  s.version     = version
  s.date        = '2016-12-10'
  s.summary     = "Orc"
  s.description = "Orc is a model driven orchestration tool for the deployment of application clusters."
  s.authors     = ["TIMGroup"]
  s.email       = 'ignore@timgroup.com'
  s.files       = Dir.glob("{bin,lib}/**/*")
  s.homepage    =
    'https://github.com/tim-group/orc'
  s.license       = 'TIMGroup License'
  s.add_dependency('git')
end
