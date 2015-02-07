load './syntax_node.rb'

class PreprocessorNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^#/
      new_node = PreprocessorNode.new(line_counter, :preproc,    new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @cargo

    return io.string
  end
end
