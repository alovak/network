require 'benchmark'
require 'net/https'
require 'network/connection'

module Network
  def self.post(url, data, options = {})
    Connection.new(url, options).post(data)
  end
end
