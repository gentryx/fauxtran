load './detail/syntax_node.rb'

class SubroutineNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*subroutine ((\w+)\s*\((.*)\))\s*$/i
      new_node = SubroutineNode.new(line_counter, :subroutine, new_indentation, $1.chomp, comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end subroutine (\w+)\s*$/i
      terminate_clause(stack, :subroutine, line, comments)
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "void #@cargo"
    io.puts indent + "{"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent + "}"

    return io.string
  end
end
