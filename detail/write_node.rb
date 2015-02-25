load './syntax_node.rb'

class WriteNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*write\s*\(.*\)\s*.*$/i
      new_node = WriteNode.new(line_counter, :write, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts @cargo

    return io.string
  end
end
