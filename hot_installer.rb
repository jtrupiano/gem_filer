require 'highline'
# require 'ruby-debug'
require 'rubygems/gem_runner'

module HotInstaller

  # Holds name, version and source information about a gem.
  class Gem
    attr_accessor :name, :version, :source

    # new Gem data structure. The argument version should
    # respond_to? :version
    def initialize(name, version, source)
      @name, @version, @source = name, version, source
    end
    
    # convert to a space separated string
    def to_s
      "#{name} #{version.version} #{source}"
    end
    
    # Produce output in the form of arguments to the gem 
    # command
    def to_install_string
      "#{name} -v#{version.version} --source #{source}"
    end

    # Produce a list of arguments which may be passed to 
    # gem_runner.run
    def to_gem_runner_args
      return ["install", name,
              "--version", version.version,
              "--source", source]
    end
  end
  
  # Manipulate error and backtrace information into a more
  # useful form
  # def raise(*args)
  #   backtrace = caller(2)
  #   error, backtrace = 
  #     case args.size
  #     when 0 then [($!.nil? ? RuntimeError.new : $!), backtrace]
  #     when 1 then 
  #       if args[0].is_a?(String) 
  #         [RuntimeError.exception(args[0]), backtrace]
  #       else
  #         [args[0].exception, backtrace]
  #       end
  #     when 2 then
  #       [args[0].exception(args[1]), backtrace]
  #     when 3 then
  #       [args[0].exception(args[1]), args[2]]
  #     else
  #       super(ArgumentError, "wrong number of arguments", backtrace)
  #     end
  #   error.set_backtrace(backtrace)
  #   
  #   if error.is_a?(LoadError)
  #     gem_name = parse_load_error(error)
  #     ask_about_download(gem_name)
  #   end
  # end
  
  alias_method :require_without_hot_installer, :require
  def require(path)
    begin
      require_without_hot_installer(path)
    rescue LoadError => error
      gem_name = parse_load_error(error)
      raise error if ignore_gem?(gem_name)
      ask_about_download(gem_name)
    end
  end
  
  def ignore_gem?(name)
    "Win32API" == name
  end
  
  # Extract the filename from a LoadError.
  def parse_load_error(error)
    /^no such file to load -- (.*)$/.match(error.message)[1]
  end

  # Ask the user about #gem_name which cannot be found.
  def ask_about_download(gem_name)
    c = get_gemfiler_console
    c.say "\n"
    c.say "=== Cannot find required file '#{gem_name}'. ==="
    menu_config = lambda do |menu|
      menu.prompt    = "What now?"
      menu.default   = "Continue"
      menu.select_by = :index_or_name

      menu.choice "Search for available versions of a gem named #{gem_name}?" do
        gems = search_for_gems(gem_name)
        if gems.empty?
          puts "Cound not find any gems"
          false
        else
          ask_about_gems(gems)
        end
      end
      menu.choice "I know what gem this is, let me tell you what it is." do
        puts "show a prompt and ask allow them to specify all command args to gem install _______"
        true
      end
      menu.choice "Try requiring #{gem_name} again" do
        begin
          Gem.refresh
          require gem_name
        rescue LoadError
          puts "Still unable to require #{gem_name}"
          false
        end
      end
      menu.choice "I just want to quit" do
        puts "quitting..."
        exit(0)
      end
    end
    continue = c.choose(&menu_config) until continue
  end
  
  # Ask the user about installing #gems
  def ask_about_gems(gems)
    c = get_gemfiler_console
    c.say "\n"
    c.say "=== Search results ==="
    menu_config = lambda do |menu|
      menu.prompt    = "What now?"
      menu.default   = "Continue"
      menu.select_by = :index_or_name

      gems.each do |a_gem|
        menu.choice "gem install #{a_gem.to_install_string}" do
          begin
            puts a_gem.to_gem_runner_args.inspect
            ::Gem::GemRunner.new.run(a_gem.to_gem_runner_args)
          rescue error
            puts error.backtrace
          end
        end
      end
      menu.choice "Go back to main menu"
    end
    c.choose(&menu_config)
  end
  
  def get_gemfiler_console
    @gemfiler_console ||= HighLine.new($stdin, $stderr)
  end
  
  def gem_fetcher
    @gem_fetcher ||= ::Gem::SpecFetcher.new
  end
  
  def gem_runner
    @gem_runner ||= ::Gem::GemRunner.new
  end
  
  # Search for gems matching #gem_name, and add their information
  # to the collection.
  def search_for_gems(gem_name)
    gems = gem_fetcher.find_matching(::Gem::Dependency.new(gem_name, nil))
    gems.map {|gem|
      HotInstaller::Gem.new(gem[0][0], gem[0][1], gem[1])
    }
  end
  
end

class ::Object
  include ::HotInstaller
  # Debugger.start
end


if $0 == __FILE__
  require 'thor'
  require 'faker'
end
