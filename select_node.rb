load './syntax_node.rb'

class SelectNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s+select case\s*\(.*\)\s*$/i
      new_node = SelectNode.new(line_counter, :select, new_indentation, line.chomp, comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s+case\s*\((.+)\)\s*$/i
      stack.last.add_case("case #$1:")
      return true
    end

    if line =~ /^\s+case\s*default\s*$/i
      stack.last.add_case("else")
      return true
    end

    if line =~ /^\s+end\s+select\s*$/i
      SyntaxNode.terminate_clause(stack, :select, line, comments)
      return true
    end

    return false
  end

  def initialize(line_counter, type, indentation, cargo, comments)
    super(line_counter, type, indentation, cargo, comments)
    @case_conditions = []
    @case_statements = []
  end

  def add_case(condition)
    @case_conditions << condition
    @case_statements << []
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts "// #{comment}"
    end
    io.puts "switch (fixme) {"

    @case_conditions.size.times do |i|
      io.puts @case_conditions[i]
      @case_statements[i].each { |node| node.to_cpp(io) }
      io.puts "break;"
    end

    io.puts "}"

    return io.string
  end

  def <<(node)
    @case_statements.last << node
  end

  def dot_nodes
    ret = super

    @case_conditions.times do |i|
      ret << "node_#{@line_counter}_case_#{i} [label=\"#{@case_conditions[i]}\"]"

      @case_statements[i].each do |node|
        ret += node.dot_nodes
      end
    end

    ret.flatten
  end

  def dot_edges
    ret = super

    @case_conditions.times do |i|
      ret << "node_#{@line_counter} -> node_#{@line_counter}_case_#{i}"

      @case_statements[i].each do |node|
        ret << "node_#{@line_counter}_case_#{i} -> node_#{child.line_counter}"
      end
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
