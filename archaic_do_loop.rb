load './syntax_node.rb'

class ArchaicDoLoop < SyntaxNode
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
