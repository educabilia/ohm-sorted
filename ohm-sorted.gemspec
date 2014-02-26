Gem::Specification.new do |s|
  s.name        = 'ohm-sorted'
  s.version     = '0.3.4'
  s.summary     = "Sorted indices for Ohm."
  s.description = "An plugin for Ohm that lets you create sorted indices."
  s.author      = "Federico Bond"
  s.email       = 'federico@educabilia.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/educabilia/ohm-sorted'
  s.license     = 'UNLICENSE'

  s.add_development_dependency "appraisal"
  s.add_development_dependency "ohm"
  s.add_development_dependency "ohm-contrib"
end
