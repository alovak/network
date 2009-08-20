require "rubygems"
require "ruby-debug"
require "test/unit"
require "mocha"

begin
  require 'turn'
rescue LoadError
end

require 'lib/network'
