require_relative 'syntax_node'

class ReadNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*read\(.*\)/i
      new_node = ReadNode.new(line_counter, :read, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts @cargo

    return io.string
  end
end
