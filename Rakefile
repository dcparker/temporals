require 'rubygems'
require 'hoe'
require './lib/time_point'

Dir['tasks/**/*.rake'].each { |rake| load rake }

Hoe.new('time_point', TimePoint::VERSION) do |p|
  p.author      = 'Daniel Parker'
  p.email       = 'gems@behindlogic.com'
  p.summary     = "A parser for definitions of recurring events in natural English."
  p.description = "A parser for definitions of recurring events in natural English."
  p.url         = 'http://github.com/dcparker/time_point'
  p.changes     = p.paragraphs_of('History.txt', 0..1).join("\n\n")
end

desc "Generate gemspec"
task :gemspec do |x|
  # Check the manifest before generating the gemspec
  manifest = %x[rake check_manifest]
  manifest.gsub!(/\(in [^\)]+\)\n/, "")

  unless manifest.empty?
    print "\n", "#"*68, "\n"
    print <<-EOS
  Manifest.txt is not up-to-date. Please review the changes below.
  If the changes are correct, run 'rake check_manifest | patch'
  and then run this command again.
EOS
    print "#"*68, "\n\n"
    puts manifest
  else
    gemspec = `rake debug_gem`
    gemspec.gsub!(/\(in [^\)]+\)\n/, "")
    File.open("time_point.gemspec", 'w') {|f| f.write(gemspec) }
  end
end