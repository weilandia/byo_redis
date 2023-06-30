# frozen_string_literal: true

require "socket"
require "pry"
require_relative "redis_serialization_protocol"

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

      readable, writable, = IO.select(watching)

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
    resp = client.recv(1024)

    if resp == ""
      clients.delete(client)
      client.close
      return
    end

    instructions = RedisSerializationProtocol.new.parse(resp)
    handle_instructions(instructions, client)
  end

  def handle_instructions(instructions, client)
    i = 0

    while i < instructions.length
      instruction = instructions[i]

      if instruction[:type] == :array
        handle_instructions(instruction[:value], client)
        i += instruction[:value].length
      else
        puts instructions
        progress = handle_command(instructions, client)
        i += progress
      end
    end
  end

  def handle_command(instructions, client)
    command = instructions[0][:value]

    case command
    when /PING/i
      client.write(simple_string("PONG"))
      1
    when /ECHO/i
      client.write(bulk_string(instructions[1][:value]))
      2
    else
      client.write(simple_string("OK"))
    end
  end

  def simple_string(string)
    "+#{string}\r\n"
  end

  def bulk_string(string)
    "$#{string.length}\r\n#{string}\r\n"
  end

  def error(string)
    "-#{string}\r\n"
  end
end

YourRedisServer.new(6379).listen
