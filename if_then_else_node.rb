load './syntax_node.rb'

class IfThenElseNode < SyntaxNode
  # "if" expressions can be tricky due to nested brackets. regular
  # expressions can't really match them as regular expressions are
  # essentially finite state machines while brackets may be nested
  # arbitrarily often. we cheat and assume at most k levels of nesting
  # (given by the for-loop). tricky: match trailing expression. that's
  # caught by match group f(k) with
  #
  #   f(1) = 3
  #   f(k) = (f(k-1) - 1) * 3
  fragment = '[^\(\)\n]*'
  4.times do
    fragment = '(' + fragment + '\(' + fragment + '\))*' + fragment
  end
  expression = '^\s*if\s*\((' + fragment + ')\)\s*(.*)$'
  @if_expression = /#{expression}/i

  def self.accept(line, stack, line_counter, new_indentation, comments, parser)
    if line =~ /#{@if_expression}/i
      trailing_expression = $42

      new_node = IfThenElseNode.new(line_counter, :if, new_indentation, line.chomp, comments)
      stack.last << new_node
      stack << new_node

      if !(trailing_expression =~ /^then\s*$/i)
        parser.parse_line(line_counter.to_s + "b", stack, trailing_expression, [])
        stack.pop
      end

      return true
    end


    if line =~ /^\s+else\s*(.*)$/i
      stack.last.add_else_branch
      remainder = $1
      # drop last if-clause from stack as "if...else if ... endif" needs
      # only one endif, not two, in Fortran.
      if remainder =~ /^if/i
        stack.pop
      end
      parser.parse_line(line_counter.to_s + "b", stack, remainder, comments)

      return true
    end

    if line =~ /^\s*end\s*if/i
      SyntaxNode.terminate_clause(stack, :if, line, comments)
      return true
    end

    return false
  end

  def add_else_branch
    @else = []
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts @indent + "// #{comment}"
    end

    io.puts @indent + "if (fixme) {"
    @children.each { |node| node.to_cpp(io) }

    if @else
      io.puts @indent + "} else {"
      @else.each { |node| node.to_cpp(io) }
    end

    io.puts @indent + "}"

    return io.string
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

