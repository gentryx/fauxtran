load './syntax_node.rb'

class ModuleNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*module (\w+)/i
      new_node = ModuleNode.new(line_counter, :module, new_indentation, $1.chomp, comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end module\s+(\w+)\s*$/i
      terminate_clause(stack, :module, line, comments)
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent +  "namespace #{@cargo} {"
    @children.each { |node| node.to_cpp(io) }
    io.puts @indent +  "}"

    return io.string
  end
end
