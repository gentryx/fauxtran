load './syntax_node.rb'

class UseNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*use,? (\w+)/i
      new_node = UseNode.new(line_counter, :using, new_indentation, $1, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "using namespace #@cargo;"

    return io.string
  end
end
