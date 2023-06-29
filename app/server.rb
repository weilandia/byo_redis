require "socket"

class YourRedisServer
  def initialize(port)
    @port = port
  end

  def start
    loop do
      server = TCPServer.new(@port)
      client = server.accept

      request = client.gets

      client.write("+PONG\r\n")
      client.close
    end
  end
end

YourRedisServer.new(6379).start
