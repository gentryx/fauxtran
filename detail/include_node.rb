load './detail/syntax_node.rb'

class IncludeNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*include\s*(.+)$/
      new_node = IncludeNode.new(line_counter, :include, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// INCLUDE #{comment}"
    end

    io.puts @cargo

    return io.string
  end
end
