require 'rubygems'

def parse_load_error(error)
  /^no such file to load -- (.*)$/.match(error.message)[1]
end

$fetcher = nil
$last_message = ""
begin
  #load $1
  require 'abc'
  require 'def'
rescue LoadError => er
  if $last_message == er.message
    $stderr.puts "Same error twice in a row: #{$last_message}"
    exit 1
  end
  $last_message = er.message
  $fetcher ||= Gem::SpecFetcher.new

  gems = fetcher.find_matching(Gem::Dependency.new(gem_name, nil))
  gem_name = parse_load_error(er)
  if gems.empty?
    puts "gem #{gem_name}"
  else
    version = gems[0][0][1].version
    puts "gem #{gem_name}, :version => \"#{version.to_s}\""
  end
  retry
end