require_relative 'syntax_node'

class GotoNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s+goto\s+(\w+)\s*$/i
      new_node = GotoNode.new(line_counter, :goto, new_indentation, line.chomp, comments)
      stack.last << new_node

      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "// GOTO" + @cargo

    return io.string
  end
end
