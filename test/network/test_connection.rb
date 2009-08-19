require 'test_helper'

class TestConnection < Test::Unit::TestCase
  def setup
    @connection = Network::Connection.new("http://example.com/path")
  end

  def test_network_exceptions
    [ { :class => Timeout::Error,       :message => "The connection to the remote server is timed out" },
      { :class => EOFError,             :message => "The connection to the remote server was dropped"},
      { :class => Errno::ECONNRESET,    :message => "The remote server reset the connection"},
      { :class => Errno::ECONNABORTED,  :message => "The remote server reset the connection"},
      { :class => Errno::ECONNREFUSED,  :message => "The connection was refused by the remote server"},
    ].each do |exception|
      Net::HTTP.any_instance.expects(:request).raises exception[:class]
      e = assert_raise Network::Error do
        @connection.post("some data")
      end
      assert_equal exception[:message], e.message
    end
  end

  def test_default_timeouts
    assert_equal Network::Connection::READ_TIMEOUT, @connection.read_timeout
    assert_equal Network::Connection::OPEN_TIMEOUT, @connection.open_timeout
  end

  def test_change_timeouts
    @connection.read_timeout = 10
    @connection.open_timeout = 20
    assert_equal 10, @connection.read_timeout
    assert_equal 20, @connection.open_timeout
  end

  def test_default_headers_for_post_request
    Net::HTTP.any_instance.expects(:post).with("/path", "data", 
                                               { 'Content-Type'   => 'application/x-www-form-urlencoded',
                                                 'Content-Length' => '4' })
    @connection.post("data")
  end

  def test_user_headers_are_not_overwrited_by_default_headers
    excepted_headers = {
      'Content-Type' => 'application/xml',
      'Accept'       => 'text/plain'
    }

    Net::HTTP.any_instance.expects(:post).with("/path",
                                               "data", 
                                               excepted_headers.update('Content-Length' => '4'))

    @connection.headers = excepted_headers
    @connection.post("data")
  end
end
