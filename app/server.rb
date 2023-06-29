require "socket"

class YourRedisServer
  MAX_COMMAND_LENGTH = 1024

  attr_reader :server, :clients

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
  end

  def listen
    loop do
      watching = [server] + clients

      readable, writable, _ = IO.select(watching)

      readable.each do |socket|
        if socket == server
          client = server.accept
          clients.push(client)
        else
          handle_client(socket)
        end
      end
    end
  end

  def handle_client(client)
    client.recv(1024)
    client.write("+PONG\r\n")
  end
end

YourRedisServer.new(6379).listen
