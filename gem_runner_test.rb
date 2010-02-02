require 'highline'
require 'ruby-debug'
require 'rubygems/gem_runner'
runner = ::Gem::GemRunner.new
runner.run(["install", "thor", "--version", "0.12.3", "--source", "http://gemcutter.org"])