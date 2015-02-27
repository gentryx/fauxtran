require 'ostruct'
load './detail/syntax_node.rb'

class SubroutineNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*subroutine\s+(\w+)\s*\((.*)\)\s*$/i

      cargo = OpenStruct.new
      cargo.name = $1
      cargo.params = $2.split(",").map { |param| param.strip }
      cargo.template_params = []
      cargo.params.size.times do |i|
        cargo.template_params << "TYPE_#{i}"
      end

      new_node = SubroutineNode.new(line_counter, :subroutine, new_indentation, cargo, comments)
      stack.last << new_node
      stack << new_node
      return true
    end

    if line =~ /^\s*end subroutine (\w+)\s*$/i
      terminate_clause(stack, :subroutine, line, comments)
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    typed_params = []
    @cargo.params.size.times do |i|
      typed_params << "#{@cargo.template_params[i]} #{@cargo.params[i]}"
    end

    template_params = @cargo.template_params.map do |param|
      "typename #{param}"
    end

    io.puts indent + "template<#{template_params.join(', ')}>"
    io.puts indent + "void #{@cargo.name}(#{typed_params.join(', ')})"
    io.puts indent + "{"
    @children.each { |node| node.to_cpp(io) }
    io.puts indent + "}"

    return io.string
  end
end
