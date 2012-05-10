require 'test_helper'

class TestLogger
  attr_reader :log

  def method_missing(method, *args)
    @log ||= ""
    @log << "#{args.first}\n"
  end
end

ResponseStub = Struct.new(:code, :message, :body)

class TestConnectionLogging < Test::Unit::TestCase

  def setup
    @connection = Network::Connection.new("http://example.com/path")
    @connection.logger = TestLogger.new
  end

  def test_log_request
    @connection.send(:log_request, "request data", "POST")
    log = @connection.logger.log

    assert_match /POST http:\/\/example.com\/path/,  log
    assert_match /--->/,                    log
    assert_match /request data/,            log
  end

  def test_log_request_with_sender
    @connection.sender = "ModuleName"
    @connection.send(:log_request, "request data", "POST")
    assert_match /ModuleName/, @connection.logger.log  
  end

  def test_log_response
    response = ResponseStub.new("200", "OK", "response data")
    @connection.send(:log_response, response, 0.16)
    log = @connection.logger.log

    assert_match /<-- 200 OK \(13 bytes 0.16ms\)/,    log
    assert_match /response data/,           log
    assert_match /----/,                    log
  end

  def test_request_filtering
    @connection.request_filter = Proc.new {|req| "#{req} is filtered"}
    @connection.send(:log_request, "request", "POST")
    assert_match /request is filtered/, @connection.logger.log
  end

  def test_response_filtering
    response = ResponseStub.new("200", "OK", "response")
    @connection.response_filter = Proc.new {|req| "#{req} is filtered"}
    @connection.send(:log_response, response)
    assert_match /response is filtered/, @connection.logger.log
  end
end

class TestConnectionWithParamsInURI < Test::Unit::TestCase
  def setup
    @connection = Network::Connection.new("http://example.com/path?route=some/where/else")
    @http = mock('http')
  end

  def test_post_methods
    sec = sequence('order')

    default_headers = { 'Content-Type'   => 'application/x-www-form-urlencoded',
                        'Content-Length' => 'hello&route=some/where/else'.bytesize.to_s }

    @http.expects(:post).with('/path', 'hello&route=some/where/else', default_headers) 

    @connection.expects(:log_request).in_sequence(sec)
    @connection.expects(:http).in_sequence(sec).returns(@http)
    @connection.expects(:log_response).in_sequence(sec)

    @connection.post("hello")
  end

  def test_get_methods
    sec = sequence('order')

    @http.expects(:get).with('/path?query=hello&route=some/where/else') 

    @connection.expects(:log_request).in_sequence(sec)
    @connection.expects(:http).in_sequence(sec).returns(@http)
    @connection.expects(:log_response).in_sequence(sec)

    @connection.get("query=hello")
  end
end

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
      e = assert_raise Network::Error do
        @connection.send(:try_request) do
          raise exception[:class]
        end
      end
      assert_equal exception[:message], e.message
    end
  end

  def test_post_methods
    sec = sequence('order')

    default_headers = { 'Content-Type'   => 'application/x-www-form-urlencoded',
                        'Content-Length' => 'hello'.bytesize.to_s }

    @http.expects(:post).with('/path', 'hello', default_headers) 

    @connection.expects(:log_request).in_sequence(sec)
    @connection.expects(:http).in_sequence(sec).returns(@http)
    @connection.expects(:log_response).in_sequence(sec)

    @connection.post("hello")
  end

  def test_get_methods
    sec = sequence('order')
    @connection.expects(:log_request).in_sequence(sec)
    @connection.expects(:http).in_sequence(sec).returns(stub('http', :get => true))
    @connection.expects(:log_response).in_sequence(sec)
    
    @connection.get("query=hello")
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
    expected_headers = { 'Content-Type'   => 'application/x-www-form-urlencoded',
                         'Content-Length' => '4' }

    assert_equal expected_headers, @connection.send(:post_headers, "data")
  end

  def test_user_headers_are_not_overwrited_by_default_headers
    user_headers = { 'Content-Type' => 'application/xml', 
                     'Accept'       => 'text/plain' }

    expected_headers = { 'Content-Length' => '4' }.update(user_headers)
    
    @connection.headers = user_headers

    assert_equal expected_headers, @connection.send(:post_headers, "data")
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
