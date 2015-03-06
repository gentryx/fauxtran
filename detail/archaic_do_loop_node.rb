load './detail/syntax_node.rb'

class ArchaicDoLoopNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*(\w+:\s*)?do(\s+\w+)?\s+(\w+)\s*=\s*([^,]+)\s*,\s*([^,]+)\s*(,[^,]+)?/i
      if !$2.nil?
        new_node = ArchaicDoLoopNode.new(line_counter, :archaic_do_loop, new_indentation, line.chomp, comments)
      else
        # complex matching to extract loop boundaries and counter increment (optional third argument)
        if line =~ /do\s+(\w+\s+)?(\w+)\s*=\s*(#{@@braced_expression}),(#{@@braced_expression})(,(#{@@braced_expression}))?/i
          # drawback of complex match: non-intuitive match indices
          cargo = OpenStruct.new
          cargo.label = $1
          cargo.index = $2
          cargo.lower = $3
          cargo.upper = $174
          cargo.stride = $346
          if cargo.stride.nil?
            cargo.stride = 1
          end
          new_node = DoLoopNode.new(line_counter, :do_loop, new_indentation, cargo, comments)
        else
          raise "failed do loop detection"
        end
      end
      stack.last << new_node
      stack << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "for (fixme) {"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent + "}"

    return io.string
  end

  def check_end(clause, line)
    return false unless line =~ /^\s*(\w+)\s+continue/i
    line_label = $1

    @cargo =~ /do\s+(\w+)/i
    loop_label = $1

    return super && (line_label == loop_label)
  end
end
