module Network
  class Connection
    attr_reader :uri
    attr_accessor :read_timeout, :open_timeout, :headers, 
                  :verify_peer, :client_certificate, :debugger_stream,
                  :ca_file

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
      begin
        http.post(uri.path, data, post_headers(data))
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

    def use_ssl?
      @uri.scheme == "https"
    end

    def client_certificate=(certificate)
      raise(ArgumentError, "Certificate must be an instance of OpenSSL::X509::Certificate") unless 
        certificate.instance_of? OpenSSL::X509::Certificate

      @client_certificate = certificate
    end

    private

    def http
      http = Net::HTTP.new(uri.host, uri.port)
      configure_timeouts(http)

      configure_ssl(http) if use_ssl?
      http
    end

    def post_headers(data)
      @headers['Content-Type']   ||= 'application/x-www-form-urlencoded'
      @headers['Content-Length'] ||= data.size.to_s
      @headers
    end

    def configure_ssl(http)
      http.use_ssl     = true
      http.cert = client_certificate

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
  end
end
