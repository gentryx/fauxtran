load './allocate_node.rb'
load './archaic_do_loop_node.rb'
load './assignment_node.rb'
load './call_node.rb'
load './continue_node.rb'
load './cycle_node.rb'
load './deallocate_node.rb'
load './default_node.rb'
load './definition_node.rb'
load './do_loop_node.rb'
load './empty_node.rb'
load './format_node.rb'
load './function_node.rb'
load './goto_node.rb'
load './if_then_else_node.rb'
load './implicit_node.rb'
load './include_node.rb'
load './module_node.rb'
load './preprocessor_node.rb'
load './print_node.rb'
load './program_node.rb'
load './read_node.rb'
load './return_node.rb'
load './root_node.rb'
load './select_node.rb'
load './stop_node.rb'
load './subroutine_node.rb'
load './syntax_node.rb'
load './use_node.rb'
load './where_loop_node.rb'
load './write_node.rb'

class FortranParser
  def initialize
    @logger = Logger.new(STDERR)
    @logger.level = Logger::INFO
  end

  def parse_file(infile)
    tree = RootNode.new("root", :root, 0, "", [])
    stack = [tree]

    File.open(infile) do |infile|
      lines = separate_comments(infile.readlines)
      lines = aggregate_lines(lines)
      lines = prune_dead_preprocessor_branches(lines)

      lines.each do |line|
        # fixme: we should also keep the line end number (in case we've aggregated some lines)
        parse_line(line[:number], stack, line[:cargo], line[:comments])
      end
    end

    return tree
  end

  def parse_line(line_counter, stack, line, comments)
    @logger.debug "at line #{line_counter}:#{stack.last.indentation} »#{line.chomp}«"
    new_indentation = stack.last.indentation + 1

    args = [line, stack, line_counter, new_indentation, comments]
    # passive nodes
    return if EmptyNode.accept(        *args)
    return if PreprocessorNode.accept( *args)
    # nesting:
    return if ModuleNode.accept(       *args)
    return if ProgramNode.accept(      *args)
    return if FunctionNode.accept(     *args)
    return if SubroutineNode.accept(   *args)
    return if SelectNode.accept(       *args)
    return if IfThenElseNode.accept(   *args, self)
    return if DoLoopNode.accept(       *args)
    return if ArchaicDoLoopNode.accept(*args)
    return if WhereLoopNode.accept(    *args)
    # subroutine header:
    return if ImplicitNode.accept(     *args)
    return if UseNode.accept(          *args)
    # definitions:
    return if DefinitionNode.accept(   *args)
    # control flow
    return if CallNode.accept(         *args)
    return if StopNode.accept(         *args)
    return if ReturnNode.accept(       *args)
    return if CycleNode.accept(        *args)
    return if GotoNode.accept(         *args)
    return if ContinueNode.accept(     *args)
    # "normal" statements
    return if FormatNode.accept(       *args)
    return if IncludeNode.accept(      *args)
    return if ReadNode.accept(         *args)
    return if WriteNode.accept(        *args)
    return if PrintNode.accept(        *args)
    return if AllocateNode.accept(     *args)
    return if DeallocateNode.accept(   *args)
    return if AssignmentNode.accept(   *args)

    raise "encounted unknown node in line #{line_counter}: »#{line}«"
  end

  # we need to strip comments first to correctly handle line continuations later on
  def separate_comments(lines)
    line_counter = 0
    raw_lines = []

    lines.each do |line|
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
        new_line[:comments] << $1
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

    return raw_lines
  end

  # handle line continuation/aggregation
  def aggregate_lines(raw_lines)
    aggregated_lines = []

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

    return aggregated_lines
  end

  # prune "#if 1" clauses. if we were doing this right, we'd need two
  # parser passes (first for c-preprocessor, second for Fortran), but
  # we really want to preserve the preprocessor statements, so we're
  # just cutting away the most superfluous stuff.
  def prune_dead_preprocessor_branches(aggregated_lines)
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

    return cleared_lines
  end

end

