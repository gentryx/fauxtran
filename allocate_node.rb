load './syntax_node.rb'

class AllocateNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*allocate\s*\(.+\)\s*$/i
      new_node = AllocateNode.new(line_counter, :allocate, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + "malloc(#@cargo, fixme);"

    return io.string
  end
end
