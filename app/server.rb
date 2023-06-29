require "socket"
require "pry"

class RedisServer
  attr_reader :server, :clients

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
  end

  def listen
    loop do
      watching = [server] + clients
      ready_to_read, _, _ = IO.select(watching)

      ready_to_read.each do |ready|
        if ready == server
          puts "New client connected."
          clients << server.accept
        else
          handle_client(ready)
        end
      end
    end
  end

  def handle_client(client)
    command = client.recv(1024)
    client.write("+PONG\r\n")
  rescue Errno::ECONNRESET
    clients.delete(client)
    puts "Client disconnected."
  end
end

RedisServer.new(6379).listen
