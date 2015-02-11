load './syntax_node.rb'

class DefaultNode < SyntaxNode
  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end
    io.puts indent + "// FORTRAN: #@type: #@cargo"
    @children.each { |node| node.to_cpp(io) }

    return io.string
  end
end
