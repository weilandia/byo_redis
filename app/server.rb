require "socket"

class YourRedisServer
  MAX_COMMAND_LENGTH = 1024

  def initialize(port)
    @port = port
  end

  def start
    server = TCPServer.new(@port)
    client = server.accept

    until client.eof?
      client.gets
      client.write("+PONG\r\n")
    end
  end
end

YourRedisServer.new(6379).start
