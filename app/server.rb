# frozen_string_literal: true

require "socket"
require_relative "redis_serialization_protocol"

class Server
  MAX_COMMAND_LENGTH = 1024

  attr_reader :server, :clients, :store
  attr_accessor :prev_key

  def initialize(port)
    @server = TCPServer.new(port)
    @clients = []
    @store = {}
    @prev_key = nil
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
    print "RESP: #{resp}"
    puts "INSTRUCTIONS: #{instructions}"
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
        progress = handle_command(instructions, client)
        puts "CURRENT STORE: #{store}"
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
    when /SET/i
      key = instructions[1][:value]
      value = instructions[2][:value]
      expiry = nil

      instructions[3..].each_slice(2) do |flag|
        case flag[0][:value]
        when /EX/i
          expiry = flag[1][:value] * 1000
        when /PX/i
          expiry = flag[1][:value]
        end
      end

      store[key] = { value: value, time: Time.now, expiry: expiry }
      client.write(simple_string("OK"))
      instructions.length + 1
    when /PX/i
      key = prev_key
      expiry = instructions[1][:value]
      obj = store[key]
      obj[:expiry] = expiry
    when /GET/i
      key = instructions[1][:value]
      obj = store[key]

      unless obj
        client.write(null_bulk_string)
        return 2
      end

      elapsed = (Time.now - obj[:time]) * 1000.0
      expired = obj[:expiry] && elapsed > obj[:expiry].to_i

      if expired
        store.delete(key)
        client.write(null_bulk_string)
      else
        client.write(bulk_string(obj[:value]))
      end

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

  def null_bulk_string
    "$-1\r\n"
  end

  def time_difference_in_milliseconds(start, finish)
    (finish - start) * 1000.0
  end
end

Server.new(6379).listen
