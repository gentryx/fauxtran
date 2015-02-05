load './syntax_node.rb'

class DefaultNode < SyntaxNode
  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts "// #{comment}"
    end
    io.puts "// FORTRAN: #@type: #@cargo"
    @children.each { |node| node.to_cpp(io) }

    return io.string
  end

end
