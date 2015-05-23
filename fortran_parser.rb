require_relative 'detail/allocate_node'
require_relative 'detail/archaic_do_loop_node'
require_relative 'detail/assignment_node'
require_relative 'detail/call_node'
require_relative 'detail/continue_node'
require_relative 'detail/cycle_node'
require_relative 'detail/data_node'
require_relative 'detail/deallocate_node'
require_relative 'detail/default_node'
require_relative 'detail/definition_node'
require_relative 'detail/do_loop_node'
require_relative 'detail/empty_node'
require_relative 'detail/format_node'
require_relative 'detail/function_node'
require_relative 'detail/goto_node'
require_relative 'detail/if_then_else_node'
require_relative 'detail/implicit_node'
require_relative 'detail/include_node'
require_relative 'detail/module_node'
require_relative 'detail/preprocessor_node'
require_relative 'detail/print_node'
require_relative 'detail/program_node'
require_relative 'detail/read_node'
require_relative 'detail/return_node'
require_relative 'detail/root_node'
require_relative 'detail/select_node'
require_relative 'detail/stop_node'
require_relative 'detail/subroutine_node'
require_relative 'detail/syntax_node'
require_relative 'detail/use_node'
require_relative 'detail/where_loop_node'
require_relative 'detail/write_node'

class FortranParser
  def initialize(user_defined_nodes=[])
    @logger = Logger.new(STDERR)
    @logger.level = Logger::INFO
    @user_defined_nodes = user_defined_nodes
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
    return if DataNode.accept(         *args)
    return if ReadNode.accept(         *args)
    return if WriteNode.accept(        *args)
    return if PrintNode.accept(        *args)
    return if AllocateNode.accept(     *args)
    return if DeallocateNode.accept(   *args)
    return if AssignmentNode.accept(   *args)

    @user_defined_nodes.each do |node|
      return if node.accept(*args)
    end

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
      when (line =~ /^c(.*)/i) || (line =~ /^\s*!(.*)$/i)
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

