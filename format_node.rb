load './syntax_node.rb'

class FormatNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*\d*\s*format\(.*\)/i
      new_node = FormatNode.new(line_counter, :format,    new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + "// FORMAT: #@cargo"

    return io.string
  end
end
