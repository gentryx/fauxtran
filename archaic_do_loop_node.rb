load './syntax_node.rb'

class ArchaicDoLoopNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*(\w+:\s*)?do(\s+\w+)?\s+(\w+)\s*=\s*([^,]+)\s*,\s*([^,]+)\s*(,[^,]+)?/i
      if !$2.nil?
        new_node = ArchaicDoLoopNode.new(line_counter, :archaic_do_loop, new_indentation, line.chomp, comments)
      else
        new_node = DefaultNode.new(line_counter, :do_loop, new_indentation, line.chomp, comments)
      end
      stack.last << new_node
      stack << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts "// #{comment}"
    end

    io.puts "for (fixme) {"
    @children.each { |node| node.to_cpp(io) }
    io.puts "}"

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
