# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{time_point}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Parker"]
  s.date = %q{2009-08-21}
  s.description = %q{A parser for definitions of recurring events in natural English.}
  s.email = %q{gems@behindlogic.com}
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "lib/time_point.rb", "spec/time_point_spec.rb"]
  s.homepage = %q{http://github.com/dcparker/time_point}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{time_point}
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{A parser for definitions of recurring events in natural English.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<hoe>, [">= 1.8.3"])
    else
      s.add_dependency(%q<hoe>, [">= 1.8.3"])
    end
  else
    s.add_dependency(%q<hoe>, [">= 1.8.3"])
  end
end
