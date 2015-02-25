load './detail/syntax_node.rb'

class DoLoopNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*do while (.+)$/i
      new_node = DoLoopNode.new(line_counter, :do_loop, new_indentation, $1.chomp, comments)
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

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    buf = ""
    if @cargo.class == Array
      buf += "#{@cargo[1]} = #{@cargo[2]}; #{@cargo[1]} <= #{@cargo[3]}; "
      if @cargo[4].nil?
        buf += "++#{@cargo[1]}"
      else
        buf += "#{@cargo[1]} += #{@cargo[4]}"
      end
    else
      buf = "fixme #{@cargo}"
    end

    io.puts indent +  "for (#{buf}) {"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent +  "}"

    return io.string
  end
end
