require 'test_helper'

class TestConnection < Test::Unit::TestCase
  def setup
    @connection = Network::Connection.new("http://example.com/path")
    @http = mock('http')
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

  def test_configure_ssl_if_scheme_is_https
    assert Network::Connection.new("https://example.com").use_ssl?
    assert !Network::Connection.new("http://example.com").use_ssl?
  end

  def test_default_debug
    assert_equal nil, @connection.debugger_stream
  end

  def test_change_debug
    @connection.debugger_stream = STDOUT
    assert_equal STDOUT, @connection.debugger_stream
  end

  def test_default_ssl_verify_mode
    assert_equal false, @connection.verify_peer
  end

  def test_ssl_verify_peer_mode
    @connection.verify_peer = true
    assert_equal true, @connection.verify_peer
  end

  def test_timeouts_configuration
    @http.expects(:read_timeout=)
    @http.expects(:open_timeout=)
    @connection.send(:configure_timeouts, @http)
  end

  def test_debugging_configuration
    @http.expects(:set_debug_output)
    @connection.send(:configure_debugging, @http)
  end

  def test_ssl_configuration_without_server_certification_verification
    @http.expects(:use_ssl=)
    @http.expects(:verify_mode=).with(Network::Connection::VERIFY_NONE)
    @http.expects(:ca_file=).never
    
    @connection.send(:configure_ssl, @http)
  end

  def test_ssl_configuration_with_server_certification_verification
    @connection.verify_peer = true
    @http.expects(:use_ssl=)
    @http.expects(:verify_mode=).with(Network::Connection::VERIFY_PEER)
    @http.expects(:ca_file=)
    
    @connection.send(:configure_ssl, @http)
  end

  def test_ssl_configuration_with_client_pem_file
    @connection.pem_file('test/test.pem')
    @http.expects(:use_ssl=)
    @http.expects(:cert=)
    @http.expects(:key=)
    @http.expects(:verify_mode=).with(Network::Connection::VERIFY_NONE)
 
    @connection.send(:configure_ssl, @http)
  end
end
