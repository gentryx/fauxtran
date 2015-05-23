require_relative 'syntax_node'

class DefinitionNode < SyntaxNode
  def self.accept(line, stack, line_counter, new_indentation, comments)
    if line =~ /^\s*(((character|complex|integer|real|logical|double precision)\*?(\([^\)\n]+\))?)(,\s*\w+(\([^\)\n]+\))?)*)\s*(::)?\s+(\w+(\([^\)\n]*\))?(\s*,\s*\w+(\([^\)\n]+\))?)*)\s*$/i

      type = $1.chomp
      names = $8.chomp

      case type.downcase
      when "character"
          type = "char"
      when "complex"
          type = "std::complex"
      when "integer"
        type = "int"
      when "real"
        type = "float"
      when "double precision"
        type = "double"
      when "logical"
        type = "bool"
      when "real(kind=mg_real)"
      # fixme: quick'n'dirty hack
        type = "double"
      else
        type = "// FIXME: definition #{type}"
      end

      cargo = {
        :type => type,
        :names => names
      }
      new_node = DefinitionNode.new(line_counter, :definition, new_indentation, cargo, comments)
      stack.last << new_node
      return true
    end

    return false
  end

  def to_cpp(io = StringIO.new)
    @comments.each do |comment|
      io.puts indent + "// #{comment}"
    end

    io.puts indent + "#{@cargo[:type]} #{@cargo[:names]};"

    return io.string
  end
end
