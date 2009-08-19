module Network
  class Connection
    attr_reader :uri
    attr_accessor :read_timeout, :open_timeout, :headers

    READ_TIMEOUT = 5
    OPEN_TIMEOUT = 5

    def initialize(uri)
      @uri = URI.parse(uri)
      @read_timeout = READ_TIMEOUT
      @open_timeout = OPEN_TIMEOUT
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

    private

    #def http
      #http = Net::HTTP.new(uri.host, uri.port)
      #http.
    #end

    def post_headers(data)
      @headers['Content-Type']   ||= 'application/x-www-form-urlencoded'
      @headers['Content-Length'] ||= data.size.to_s
      @headers
    end
  end
end
