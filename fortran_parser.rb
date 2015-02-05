def terminate_clause(stack, clause, line, comments)
  stack.last.add_comments(comments)

  if stack.last.check_end(clause, line)
    stack.pop
  else
    raise "clause :#{clause.to_s} does not match :#{stack.last.type.to_s}, »#{stack.last.cargo}«"
  end
end

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
IF_EXPRESSION = /#{expression}/i

def parse_line(line_counter, stack, line, comments)
  @logger.debug "at line #{line_counter}:#{stack.last.indentation} »#{line.chomp}«"

  new_indentation = stack.last.indentation + 1

  case
    # passive nodes
  when line =~ /^\s*$/
    new_node = SyntaxNode.new(line_counter, :empty,      new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^#/
    new_node = SyntaxNode.new(line_counter, :preproc,    new_indentation, line.chomp, comments)
    stack.last << new_node

    # nesting:
  when line =~ /^\s*module (\w+)/i
    new_node = SyntaxNode.new(line_counter, :module, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
  when line =~ /^\s*end module (\w+)/i
    terminate_clause(stack, :module, line, comments)

  when line =~ /^\s*program (\w+)/i
    new_node = SyntaxNode.new(line_counter, :program, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
  when line =~ /^\s*end program (\w+)/i
    terminate_clause(stack, :program, line, comments)

  when line =~ /^\s*function (\w+)\s*\((.*)\)/i
    new_node = SyntaxNode.new(line_counter, :function, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
  when line =~ /^\s*end function (\w+)/i
    terminate_clause(stack, :function, line, comments)

  when line =~ /^\s*subroutine (\w+)\s*\((.*)\)/i
    new_node = SyntaxNode.new(line_counter, :subroutine, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
  when line =~ /^\s*end subroutine (\w+)/i
    terminate_clause(stack, :subroutine, line, comments)

  when line =~ /^\s+select case\(.*\)\s*$/i
    new_node = SelectNode.new(line_counter, :select, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
  when line =~ /^\s+case\((.+)\)\s*$/i
    stack.last.add_case($1)
  when line =~ /^\s+end\s+select\s*$/i
    terminate_clause(stack, :select, line, comments)

  when line =~ /#{IF_EXPRESSION}/i
    trailing_expression = $42

    new_node = IfThenElseNode.new(line_counter, :if, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node

    if !(trailing_expression =~ /^then\s*$/i)
      parse_line(line_counter.to_s + "b", stack, trailing_expression, [])
      stack.pop
    end
  when line =~ /^\s+else\s*(.*)$/i
    stack.last.add_else_branch
    remainder = $1
    # drop last if-clause from stack as "if...else if ... endif" needs
    # only one endif, not two, in Fortran.
    if remainder =~ /^if/i
      stack.pop
    end
    parse_line(line_counter.to_s + "b", stack, remainder, comments)
  when line =~ /^\s*end\s*if/i
    terminate_clause(stack, :if, line, comments)
    # puts "\033[1;31m KPOP! \033[0;37m"

  when line =~ /^\s*do while (.+)/i
    new_node = SyntaxNode.new(line_counter, :do_loop, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
  when line =~ /^\s*(\w+:\s*)?do(\s+\w+)?\s+(\w+)\s*=\s*([^,]+)\s*,\s*([^,]+)\s*(,[^,]+)?/i
    if !$2.nil?
      new_node = ArchaicDoLoop.new(line_counter, :archaic_do_loop, new_indentation, line.chomp, comments)
    else
      new_node = SyntaxNode.new(line_counter, :do_loop, new_indentation, line.chomp, comments)
    end
    stack.last << new_node
    stack << new_node
    # puts "\033[1;32m PUSH! \033[0;37m"
  when line =~ /^\s*end\s*do/i
    terminate_clause(stack, :do_loop, line, comments)
    # puts "\033[1;31m KPOP! \033[0;37m"

  when line =~ /^\s*where (.+)/i
    new_node = SyntaxNode.new(line_counter, :where_loop, new_indentation, line.chomp, comments)
    stack.last << new_node
    stack << new_node
    # puts "\033[1;32m PUSH! \033[0;37m"
  when line =~ /^\s*end where/i
    terminate_clause(stack, :where_loop, line, comments)
    # puts "\033[1;31m KPOP! \033[0;37m"

    # subroutine header:
  when line =~ /^\s+implicit none/i
    new_node = SyntaxNode.new(line_counter, :implicit,   new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*use,? (\w+)/i
    new_node = SyntaxNode.new(line_counter, :using,      new_indentation, line.chomp, comments)
    stack.last << new_node

    # definitions:
    #fixme: unite these definition patterns
  when line =~ /^\s*character(\(\w+\))?,? (.+)/i
    new_node = SyntaxNode.new(line_counter, :definition, new_indentation, line.chomp, comments)
    stack.last << new_node

  when line =~ /^\s*complex(\(\w+\))?,? (.+)/i
    new_node = SyntaxNode.new(line_counter, :definition, new_indentation, line.chomp, comments)
    stack.last << new_node

  when line =~ /^\s*integer(\(\w+\))?,? (.+)/i
    new_node = SyntaxNode.new(line_counter, :definition, new_indentation, line.chomp, comments)
    stack.last << new_node

    #andi1 fixme
  when line =~ /^\s*real(\([^\)\n]*\))?,?(.*)$/i
    new_node = SyntaxNode.new(line_counter, :definition, new_indentation, line.chomp, comments)
    stack.last << new_node

  when line =~ /^\s*logical(\(\w+\))?,? (.+)/i
    new_node = SyntaxNode.new(line_counter, :definition, new_indentation, line.chomp, comments)
    stack.last << new_node

    # control flow
  when line =~ /^\s*call\s+\w+\s*(\(.*\)\s*)?$/i
    new_node = SyntaxNode.new(line_counter, :call,       new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*stop\s+$/i
    new_node = SyntaxNode.new(line_counter, :stop,       new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*return\s*$/i
    new_node = SyntaxNode.new(line_counter, :return,     new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*cycle\s*$/i
    new_node = SyntaxNode.new(line_counter, :cycle,      new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^(\s*\d+)?\s+continue\s*$/i
    if stack.last.check_end(:archaic_do_loop, line)
      terminate_clause(stack, :archaic_do_loop, line, comments)
    else
      new_node = SyntaxNode.new(line_counter, :continue, new_indentation, line.chomp, comments)
      stack.last << new_node
    end
  when line =~ /^\s+goto\s+(\w+)\s*$/i
    new_node = SyntaxNode.new(line_counter, :goto, new_indentation, line.chomp, comments)
    stack.last << new_node

    # "normal" statements
  when line =~ /^\s*\d*\s*format\(.*\)/i
    new_node = SyntaxNode.new(line_counter, :format,     new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*read\(.*\)/i
    new_node = SyntaxNode.new(line_counter, :read,       new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*write\s*\(.*\)\s+.+$/i
    new_node = SyntaxNode.new(line_counter, :write,      new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*print /i
    new_node = SyntaxNode.new(line_counter, :print,      new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^\s*allocate\(.*\)/i
    new_node = SyntaxNode.new(line_counter, :allocate,   new_indentation, line.chomp, comments)
    stack.last << new_node
  when line =~ /^(\s\d+)?\s*([^,]+(,[^,]+)*)(\(:?\w*\))?\s*=/i
    new_node = SyntaxNode.new(line_counter, :assignment, new_indentation, line.chomp, comments)
    stack.last << new_node

  else
    raise "encounted unknown node in line #{line_counter}: »#{line}«"
  end
end

def parse_file(infile)
  tree = SyntaxNode.new("root", :root, 0, "", [])
  stack = [tree]

  File.open(infile) do |infile|
    aggregated_lines = []
    raw_lines = []

    line_counter = 0
    # we need to strip comments first to correctly handle line continuations later on
    infile.readlines.each do |line|
      line_counter += 1
      new_line = {
        :number => line_counter,
        :end => line_counter,
        :cargo => "",
        :comments => []
      }

      case
      when line =~ /^c(.*)/i
        # we need to strip pure comment lines and append those to the
        # preceeding line to ensure continuation works correctly
        if raw_lines.size > 0
          # we can only append if there actually is a preceeding line
          raw_lines[-1][:comments] << $1
          next
        end
        new_line[:comments] = $1
      when line =~ /^([^\!]*)\!(.*)$/
        new_line[:cargo] += $1
        new_line[:comments] << $2
      when line =~ /^$/
        # drop empty lines, also required to correctly fuse continued
        # lines (continuations ignore interleaved empty lines).
        next
      else
        new_line[:cargo] += line.chomp
      end

      raw_lines << new_line
    end

    # handle line continuation/aggregation
    raw_lines.each do |line|
      if line[:cargo] =~ /^\s+\&\s*(.*)$/
        raise "no preceeding line to fuse with" if aggregated_lines.size == 0
        aggregated_lines[-1][:cargo] += " " + $1
        aggregated_lines[-1][:comments] += line[:comments]
        aggregated_lines[-1][:end] = line[:number]
        next
      end

      if (aggregated_lines.size > 0) && (aggregated_lines[-1][:cargo] =~ /^(.*)\&\s*$/)
        aggregated_lines[-1][:cargo] = $1.strip + " " + line[:cargo].strip
        aggregated_lines[-1][:comments] += line[:comments]
        aggregated_lines[-1][:end] = line[:number]
        next
      end

      aggregated_lines << line
    end

    # prune "#if 1" clauses. if we were doing this right, we'd need two
    # parser passes (first for c-preprocessor, second for Fortran), but
    # we really want to preserve the preprocessor statements, so we're
    # just cutting away the most superfluous stuff.
    cleared_lines = []
    state = :discharged
    aggregated_lines.each do |line|
      if line[:cargo] =~ /^#if 1/
        state = :charged
      end

      if line[:cargo] =~ /^#endif/
        state = :discharged
      end

      if (line[:cargo] =~/^#else/) && (state == :charged)
        state = :ablaze
      end

      if state != :ablaze
        cleared_lines << line
      end
    end

    cleared_lines.each do |line|
      # fixme: we should also keep the line end number (in case we've aggregated some lines)
      parse_line(line[:number], stack, line[:cargo], line[:comments])
    end

  end

  return tree
end
