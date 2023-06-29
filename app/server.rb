require "socket"

class YourRedisServer
  MAX_COMMAND_LENGTH = 1024

  def initialize(port)
    @port = port
  end

  def start
    server = TCPServer.new(@port)
    client = server.accept

    loop do
      client.recv(MAX_COMMAND_LENGTH)
      client.write("+PONG\r\n")
    rescue Errno::ECONNRESET
      puts "The connection is terminated by the client."
      break
    end

    client.close
  end
end

YourRedisServer.new(6379).start
