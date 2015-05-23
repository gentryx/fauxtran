require_relative 'syntax_node'

class DoLoopNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*do while (.+)$/i
      new_node = DoLoopNode.new(line_counter, :do_loop, new_indentation, $1.chomp, comments, $1.chomp)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end\s*do/i
      terminate_clause(stack, :do_loop, line, comments)
      return true
    end

    return false
  end

  def one_off_limits
    @cargo.lower = "((#{cargo.lower}) - 1)"
    @cargo.upper = "((#{cargo.upper}) - 1)"
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    buf = ""
    if @cargo.class == OpenStruct
      buf += "#{@cargo.index} = #{@cargo.lower}; #{@cargo.index} <= #{@cargo.upper}; #{@cargo.index} += #{@cargo.stride}"
    else
      buf = "fixme #{@cargo}"
    end

    io.puts indent +  "for (#{buf}) {"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent +  "}"

    return io.string
  end
end
