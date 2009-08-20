require 'net/https'
require 'network/connection'
module Network
  class Error < Exception
  end

  VERSION = '1.0.0'

  def self.post(url, data)
    Connection.new(url).post(data)
  end
end
