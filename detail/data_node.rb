require_relative 'syntax_node'

class DataNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*data\s*(.+)$/
      new_node = DataNode.new(line_counter, :data, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// DATA #{comment}"
    end

    io.puts @cargo

    return io.string
  end
end
