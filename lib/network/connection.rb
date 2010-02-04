module Network
  class Error < Exception
  end

  class ResponseError < Error
    attr_reader :response
    def initialize(response)
      @response = response
    end

    def to_s
      "Failed with #{@response.code} #{@response.message if @response.respond_to?(:message)}"
    end
  end

  class Connection
    attr_reader   :uri, :pem

    attr_accessor :read_timeout, :open_timeout, :headers, 
                  :verify_peer, :ca_file,
                  :debugger_stream,
                  :logger, :request_filter, :response_filter, :sender

    READ_TIMEOUT = 60
    OPEN_TIMEOUT = 30 
    VERIFY_NONE  = OpenSSL::SSL::VERIFY_NONE
    VERIFY_PEER  = OpenSSL::SSL::VERIFY_PEER

    def initialize(uri)
      @uri = URI.parse(uri)
      @read_timeout = READ_TIMEOUT
      @open_timeout = OPEN_TIMEOUT
      @verify_peer  = false
      @debugger_stream = nil
      @headers = {}
    end

    def post(data)
      try_request do
        log_request(data)
        response = nil
        ms = Benchmark.realtime do 
          response = http.post(uri.path, data, post_headers(data))
        end
        log_response(response, ms)
        response
      end
    end

    def use_ssl?
      @uri.scheme == "https"
    end

    def pem_file(file)
      @pem = File.read(file)
    end

    private

    def http
      http = Net::HTTP.new(uri.host, uri.port)
      configure_timeouts(http)
      configure_debugging(http)

      configure_ssl(http) if use_ssl?
      http
    end

    def try_request(&block)
      begin
        block.call
      rescue Timeout::Error, Errno::ETIMEDOUT, Timeout::ExitException
        raise Error, "The connection to the remote server is timed out"
      rescue EOFError
        raise Error, "The connection to the remote server was dropped"
      rescue Errno::ECONNRESET, Errno::ECONNABORTED
        raise Error, "The remote server reset the connection"
      rescue Errno::ECONNREFUSED
        raise Error, "The connection was refused by the remote server"
      end
    end

    def post_headers(data)
      @headers['Content-Type']   ||= 'application/x-www-form-urlencoded'
      @headers['Content-Length'] ||= data.bytesize.to_s
      @headers
    end

    def configure_ssl(http)
      http.use_ssl     = true

      if pem
        http.cert = cert
        http.key  = key
      end

      if verify_peer
        http.verify_mode = VERIFY_PEER
        http.ca_file     = ca_file
      else
        http.verify_mode = VERIFY_NONE
      end
    end

    def configure_timeouts(http)
      http.read_timeout = read_timeout
      http.open_timeout = open_timeout
    end

    def configure_debugging(http)
      http.set_debug_output(debugger_stream)
    end

    def key
      OpenSSL::PKey::RSA.new(pem)
    end

    def cert
      OpenSSL::X509::Certificate.new(pem)
    end

    def log(message)
      logger.info(message) if logger
    end

    def log_request(data)
      log "[#{sender}]" if sender
      log "POST #{uri}"
      log "--->"
      log (request_filter ? request_filter.call(data) : data)
    end

    def log_response(response, ms_time = -1)
      log "<-- %s %s (%d bytes %.2fms)" % [response.code, response.message, (response.body ? response.body.bytesize : 0), ms_time]
      log (response_filter ? response_filter.call(response.body) : response.body) if response.body
      log "----"
    end
  end
end
