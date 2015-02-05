load './syntax_node.rb'

class RootNode < SyntaxNode
  def to_cpp(io = StringIO.new)
    # fixme: unify this code among all node classes?
    @comments.each do |comment|
      io.puts "// #{comment}"
    end

    @children.each { |node| node.to_cpp(io) }

    return io.string
  end
end
