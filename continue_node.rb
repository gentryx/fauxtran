load './syntax_node.rb'

class ContinueNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^(\s*\d+)?\s+continue\s*$/i
      if stack.last.check_end(:archaic_do_loop, line)
        SyntaxNode.terminate_clause(stack, :archaic_do_loop, line, comments)
      else
        new_node = ContinueNode.new(line_counter, :continue, new_indentation, line.chomp, comments)
        stack.last << new_node
      end

      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "// CONTINUE" + @cargo

    return io.string
  end
end
