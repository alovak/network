require 'benchmark'
require 'net/https'
require 'network/connection'

module Network
  def self.post(url, data, options = {})
    Connection.new(url, options).post(data)
  end

  def self.get(url, data, options = {})
    Connection.new(url, options).get(data)
  end

end
