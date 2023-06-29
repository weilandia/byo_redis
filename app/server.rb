require "socket"

class YourRedisServer
  MAX_COMMAND_LENGTH = 1024

  def initialize(port)
    @port = port
  end

  def start
    server = TCPServer.new(@port)
    socket = server.accept

    loop do
      Thread.new do
        socket.recv(MAX_COMMAND_LENGTH)
        socket.write("+PONG\r\n")
      end
    end
  end
end

YourRedisServer.new(6379).start
