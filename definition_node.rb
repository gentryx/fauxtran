load './syntax_node.rb'

class DefinitionNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*((character|complex|integer|real|logical)(\(\w+(=\w+)?\))?,?\s+(.+))/i
      new_node = DefinitionNode.new(line_counter, :definition, new_indentation, $1.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + "// DEFINITION: #@cargo"

    return io.string
  end
end
