load './syntax_node.rb'

class StopNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*stop\s+$/i
      new_node = StopNode.new(line_counter, :stop, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "// STOP" + @cargo

    return io.string
  end
end
