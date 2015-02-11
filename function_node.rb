load './syntax_node.rb'

class FunctionNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*(.*)\s*function (\w+)\s*\((.*)\)/i
      new_node = FunctionNode.new(line_counter, :function, new_indentation, "#{$1}(#{$2})", comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end function (\w+)\s*$/i
      terminate_clause(stack, :function, line, comments)
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "void #@cargo {"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent + "}"

    return io.string
  end
end
