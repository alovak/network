require 'benchmark'
require 'net/https'
require 'network/connection'

module Network
  def self.post(url, data)
    Connection.new(url).post(data)
  end
end
