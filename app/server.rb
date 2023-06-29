require "socket"

class YourRedisServer
  def initialize(port)
    @port = port
  end

  def start
    loop do
      server = TCPServer.new(@port)
      client = server.accept

      while line = client.gets
        puts line
        client.write("+PONG\r\n")
      end

      client.close
    end
  end
end

YourRedisServer.new(6379).start
