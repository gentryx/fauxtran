require_relative 'syntax_node'

class ReturnNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*return\s*$/i
      new_node = ReturnNode.new(line_counter, :return, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "// RETURN" + @cargo

    return io.string
  end
end
