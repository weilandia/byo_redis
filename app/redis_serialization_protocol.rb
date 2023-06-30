# frozen_string_literal: true

class RedisSerializationProtocol
  def parse(string)
    i = 0
    results = []
    instructions = string.split("\r\n")

    while i < instructions.length
      instruction = instructions[i]

      if instruction[0] == "*"
        length = instruction[/\d+/].to_i * 2
        arr = parse(instructions[i + 1, i + length].join("\r\n"))
        results.push({ type: :array, value: arr })
        i += length + 1
      else
        result, add = parse_primitive(instructions[i..])
        results.push(result)
        i += add
      end
    end

    results
  end

  def pack(array)
    str = +""

    array.each do |item|
      case item[:type]
      when :simple_string
        str += "+#{item[:value]}\r\n"
      when :error
        str += "-#{item[:value]}\r\n"
      when :integer
        str += ":#{item[:value]}\r\n"
      when :bulk_string
        str += "$#{item[:value].length}\r\n#{item[:value]}\r\n"
      when :array
        str += "*#{item[:value].length}\r\n#{pack(item[:value])}"
      end
    end

    str
  end

  private

    def parse_primitive(instructions)
      instruction = instructions[0]

      case instruction[0]
      when "+"
        [{ type: :simple_string, value: instruction[1..-3] }, 1]
      when "$"
        length = instruction[/\d+/].to_i
        [{ type: :bulk_string, value: instructions[1][0, length] }, 2]
      when ":"
        [{ type: :integer, value: instruction[/\d+/].to_i }, 1]
      when "-"
        [{ type: :error, value: instruction[1..-3] }, 1]
      end
    end
end

