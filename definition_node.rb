load './syntax_node.rb'

class DefinitionNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*(character|complex|integer|real|logical)(\(\w+\))?,?\s+(.+)/i
      new_node = DefinitionNode.new(line_counter, :definition, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + @cargo

    return io.string
  end
end