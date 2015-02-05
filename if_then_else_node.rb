load './syntax_node.rb'

class IfThenElseNode < SyntaxNode
  def add_else_branch
    @else = []
  end

  def <<(node)
    if @else.nil?
      @children << node
    else
      @else << node
    end
  end

  def dot_nodes
    ret = super
    if @else
      ret += ["node_#{@line_counter}_else [label=\"else\"]"] + @else.map { |child| child.dot_nodes }
    end

    ret.flatten
  end

  def dot_edges
    ret = super
    if @else
      ret += ["node_#{@line_counter} -> node_#{@line_counter}_else"] + @else.map { |child| ["node_#{@line_counter}_else -> node_#{child.line_counter}"] + child.dot_edges }
    end

    ret.flatten
  end

  def to_s
    buf = StringIO.new
    buf.puts super

    if @else
      buf.puts @indentation.to_s.rjust(2) + @indent + ":else"

      @else.each do |c|
        buf.puts c.to_s
      end
    end

    return buf.string
  end
end

