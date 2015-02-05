load './syntax_node.rb'

class ArchaicDoLoop < SyntaxNode
  def check_end(clause, line)
    return false unless line =~ /^\s*(\w+)\s+continue/i
    line_label = $1

    @cargo =~ /do\s+(\w+)/i
    loop_label = $1

    return super && (line_label == loop_label)
  end
end
