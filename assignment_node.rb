load './syntax_node.rb'

class AssignmentNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^(\s\d+)?\s*(([^,]+(,[^,]+)*)(\(:?\w*\))?\s*=\s*.*)/i
      new_node = AssignmentNode.new(line_counter, :assignment, new_indentation, $2.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + @cargo + ";"
  end
end
