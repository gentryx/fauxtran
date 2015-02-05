load './syntax_node.rb'

class EmptyNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*$/
      new_node = EmptyNode.new(line_counter, :empty,      new_indentation, line.chomp, comments)
      stack.last << new_node

      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts unless @comments.size > 0
  end
end
