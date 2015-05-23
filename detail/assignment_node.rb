require_relative 'syntax_node'

class AssignmentNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^(\s\d+)?\s*((([^,]+(,[^,]+)*)(\(:?\w*\))?)\s*=\s*(.*))/i
      cargo = [$3, $7]

      # fixme: quick hack
      cargo[0].gsub!(/%/, "_")
      cargo[1].gsub!(/%/, "_")

      new_node = AssignmentNode.new(line_counter, :assignment, new_indentation, cargo, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + @cargo[0] + " = " + @cargo[1] + ";"
  end
end
