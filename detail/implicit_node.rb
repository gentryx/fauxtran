load './syntax_node.rb'

class ImplicitNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s+(implicit none)\s*$/i
      new_node = ImplicitNode.new(line_counter, :implicit, new_indentation, $1, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "//" + @cargo

    return io.string
  end
end
