require_relative 'syntax_node'

class DeallocateNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*deallocate\s*\(.+\)\s*$/i
      new_node = DeallocateNode.new(line_counter, :deallocate, new_indentation, line.chomp, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "free(#@cargo);"

    return io.string
  end
end
