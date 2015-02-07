load './syntax_node.rb'

class ProgramNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*program\s+(\w+)\s*$/i
      new_node = ProgramNode.new(line_counter, :program, new_indentation, line.chomp, comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end program (\w+)\s*$/i
      terminate_clause(stack, :program, line, comments)
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + "// fixme #@cargo"
    @children.each { |node| node.to_cpp(io) }

    return io.string
  end
end
