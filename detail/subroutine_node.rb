require 'ostruct'
require_relative 'syntax_node'

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

  def name
    @cargo.name
  end

  def name=(new_name)
    @cargo.name = new_name
  end

  def prefix_template_param(template_param)
    @cargo.template_params = [template_param] + @cargo.template_params
  end

  def add_param(template_param, param)
    @cargo.template_params << template_param
    @cargo.params << param
  end

  def add_param_with_guard_macros(template_param, param, arity = nil)
    param_name = param + "_RAW"

    decl_params = param_name
    macro_params = ""
    array_params = ""

    if !arity.nil?
      macro_params = []
      array_params = []

      (arity.size + 1).times do |i|
        var_name = "param#{i}"
        if (i == 0)
          decl_params += "[]"
        else
          decl_params += "[#{arity[i - 1]}]"
        end
        macro_params << var_name
        array_params << "[(#{var_name}) - 1]"
      end

      macro_params = macro_params.join(", ")
      macro_params = "(#{macro_params})"
      array_params = array_params.reverse.join("")
    end

    add_param(template_param, decl_params)
    unshift(PreprocessorNode.new(-1, :preprocessor, @indentation + 1, "#define #{param}#{macro_params} #{param_name}#{array_params}"))
    push(   PreprocessorNode.new(-1, :preprocessor, @indentation + 1, "#undef #{param}"))
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    typed_params = []
    @cargo.params.size.times do |i|
      type_index = i + @cargo.template_params.size - @cargo.params.size
      typed_params << "#{@cargo.template_params[type_index]} #{@cargo.params[i]}"
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
