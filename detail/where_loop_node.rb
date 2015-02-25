load './detail/syntax_node.rb'

class WhereLoopNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*where\s+(.+)\s*$/i
      new_node = WhereLoopNode.new(line_counter, :where, new_indentation, line.chomp, comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end where\s*$/i
      terminate_clause(stack, :where, line, comments)
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "for #@cargo {"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent + "}"

    return io.string
  end
end
