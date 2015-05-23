class SyntaxNode
  attr_reader :children
  attr_reader :indentation
  attr_reader :type
  attr_reader :line_counter
  attr_accessor :cargo

  # some expressions can be tricky due to nested brackets. regular
  # expressions can't really match them as regular expressions are
  # essentially finite state machines while brackets may be nested
  # arbitrarily often. we cheat and assume at most k levels of nesting
  # (given by the for-loop below).
  fragment = '[^\(\)\,\n]*'
  4.times do
    fragment = '(' + fragment + '\(' + fragment + "(,#{fragment})*" + '\))*' + fragment
  end
  @@braced_expression = fragment

  expression = '^\s*if\s*\((' + @@braced_expression + ')\)\s*(.*)$'
  @@if_expression = /#{expression}/i

  def self.terminate_clause(stack, clause, line, comments)
    stack.last.add_comments(comments)

    if stack.last.check_end(clause, line)
      stack.pop
    else
      raise "clause :#{clause.to_s} does not match :#{stack.last.type.to_s}, »#{stack.last.cargo}«"
    end
  end

  def initialize(line_counter, type, indentation, cargo, comments, tag = "")
    @line_counter = line_counter
    @type = type
    @children = []
    @indentation = indentation
    @cargo = cargo
    @tag = tag

    if @type == :module
      # fixme: use grammar here
      @cargo =~ /module\s+(\w+)/i
      @tag = $1
    end
    if @type == :subroutine
      # fixme: use grammar here
      @tag = @cargo.name
    end
    if @type == :call
      # fixme: use grammar here
      @cargo =~ /call\s+(\w+)/i
      @tag = $1
    end
    if @type == :assignment
      # fixme: use grammar here
      # @cargo =~ /\s*(.*)/i
      # assignment = $1
      # assignment.gsub!(/"/, "")
      # @tag = assignment
    end
    if @type == :module
      # fixme: use grammar hare
      @tag = @cargo
    end

    @comments = comments
  end

  def [](index)
    @children.each do |child|
      if child.matches(*index[0])
        if index.size > 1
          return child[index[1..-1]]
        else
          return child
        end
      end
    end

    return nil
  end

  def each
    @children.each do |child|
      yield(child)
      child.each do |grandchild|
        yield(grandchild)
      end
    end
  end

  def prune(recurse=true)
    @children.delete_if { |child| yield(child) }

    return if !recurse

    @children.each do |child|
      child.prune(recurse) do |child|
        yield(child)
      end
    end
  end

  def indent(level=@indentation)
    " " * (2 * [0, level - 1].max)
  end

  # returns a string representation in GraphView's DOT format
  def to_dot(io = StringIO.new)
    io.puts "digraph AST {"
    dot_nodes.each { |node| io.puts node }
    dot_edges.each { |node| io.puts node }
    io.puts "}"

    return io.string
  end

  # convert tree to C++ code
  def to_cpp(io = StringIO.new)
    raise "implementation missing for #@type"
  end

  def add_comments(new_comments)
    @comments += new_comments
  end

  def matches(type, tag)
    return (@type == type) && (@tag == tag)
  end

  def <<(node)
    @children << node
  end

  def to_s
    buf = StringIO.new
    headline = @indentation.to_s.rjust(2) + indent + ":" + @type.to_s.ljust(10)
    if @cargo
      headline += " => »" + @cargo.to_s + "«"
    end
    buf.puts headline

    @children.each do |c|
      buf.puts c.to_s
    end

    return buf.string
  end

  def dot_label
    ret = @type.to_s
    if @tag
      ret += "<#@tag>"
    end

    return ret
  end

  def dot_nodes
    ret = ["node_#{@line_counter} [label=\"#{dot_label}\"]"] + @children.map { |child| child.dot_nodes}
    ret.flatten
  end

  def dot_edges
    ret = @children.map do |child|
      ["node_#{@line_counter} -> node_#{child.line_counter}"] + child.dot_edges
    end

    ret.flatten
  end

  def check_end(clause, line)
    return clause == @type
  end
end
