class SyntaxNode
  attr_reader :indentation
  attr_reader :type
  attr_reader :line_counter
  attr_accessor :cargo

  def initialize(line_counter, type, indentation, cargo, comments)
    @line_counter = line_counter
    @type = type
    @children = []
    @indentation = indentation
    @cargo = cargo
    @indent = " " * (2 * @indentation)

    @tag = nil
    if @type == :module
      # fixme: use grammar here
      @cargo =~ /module\s+(\w+)/i
      @tag = $1
    end
    if @type == :subroutine
      # fixme: use grammar here
      @cargo =~ /subroutine\s+(\w+)/i
      @tag = $1
    end
    if @type == :call
      # fixme: use grammar here
      @cargo =~ /call\s+(\w+)/i
      @tag = $1
    end
    if @type == :assignment
      # fixme: use grammar here
      @cargo =~ /\s*(.*)/i
      assignment = $1
      assignment.gsub!(/"/, "")
      @tag = assignment
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
    raise "implementation missing"
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
    headline = @indentation.to_s.rjust(2) + @indent + ":" + @type.to_s.ljust(10)
    if @cargo
      headline += " => »" + @cargo + "«"
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
