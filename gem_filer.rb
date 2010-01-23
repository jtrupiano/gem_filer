require 'rubygems'

class GemFiler
  class << self
    def init(options={})
      @gemfile = options.delete(:gemfile) || "Gemfile"
      @initial_specs = Gem.loaded_specs.dup
    end
    
    def should_ignore_gem?(gem_name, spec)
      @initial_specs.keys.include?(gem_name)
    end

    def generate_gemfile
      File.open(@gemfile, "w") do |file|
        Gem.loaded_specs.each_pair do |gem_name, spec|
          next if should_ignore_gem?(gem_name, spec)
          puts "Adding #{gem_name} #{spec.version.version}"
          file.write "gem '#{gem_name}', '= #{spec.version.version}'\n"
        end
      end
    end
  end
end

if $0 == __FILE__
  GemFiler.init
  require 'tzinfo'
  require 'treetop'
  GemFiler.generate_gemfile
end