load './syntax_node.rb'

class DefinitionNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*(((character|complex|integer|real|logical)(\([^\)\n]+\))?)(,\s*\w+(\([^\)\n]+\))?)*)\s*(::)?\s+(\w+(\([^\)\n]*\))?(\s*,\s*\w+(\([^\)\n]+\))?)*)\s*$/i

      cargo = $1.chomp + " " + $8.chomp
      new_node = DefinitionNode.new(line_counter, :definition, new_indentation, cargo, comments)
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
