load './syntax_node.rb'

class CallNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*call\s+\w+\s*(\(.*\)\s*)?$/i
      new_node = CallNode.new(line_counter, :call, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + @cargo

    return io.string
  end
end
