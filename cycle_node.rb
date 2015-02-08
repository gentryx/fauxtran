load './syntax_node.rb'

class CycleNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*cycle\s*$/i
      new_node = CycleNode.new(line_counter, :cycle, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + "// CYCLE" + @cargo

    return io.string
  end
end
