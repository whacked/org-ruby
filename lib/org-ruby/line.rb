module Orgmode

  # Represents a single line of an orgmode file.
  class Line

    # This is the line itself.
    attr_reader :line

    # The indent level of this line. this is important to properly translate
    # nested lists from orgmode to textile.
    # TODO 2009-12-20 bdewey: Handle tabs
    attr_reader :indent

    # Backpointer to the parser that owns this line.
    attr_reader :parser

    # A line can have its type assigned instead of inferred from its
    # content. For example, something that parses as a "table" on its
    # own ("| one | two|\n") may just be a paragraph if it's inside
    # #+BEGIN_EXAMPLE. Set this property on the line to assign its
    # type. This will then affect the value of +paragraph_type+.
    attr_accessor :assigned_paragraph_type

    def initialize(line, parser = nil)
      @parser = parser
      @line = line
      @indent = 0
      @line =~ /\s*/
      @assigned_paragraph_type = nil
      @indent = $&.length unless blank?
      @include_file = nil
      @include_lang = nil
    end

    def to_s
      return @line
    end

    # Tests if a line is a comment.
    def comment?
      check_assignment_or_regexp(:comment, /^\s*#/)
    end

    # Tests if a line contains metadata instead of actual content.
    def metadata?
      check_assignment_or_regexp(:metadata, /^\s*(CLOCK|DEADLINE|START|CLOSED|SCHEDULED):/)
    end

    def nonprinting?
      comment? || metadata?
    end

    def blank?
      check_assignment_or_regexp(:blank, /^\s*$/)
    end

    def plain_list?
      ordered_list? or unordered_list?
    end

    # Test if a line is a horizontal rule
    def horizontal_rule?
      @line =~ /\s*-{5,}\s*/
    end

    UnorderedListRegexp = /^(?:\s*(-|\+)|\s+\*)\s+/

    def unordered_list?
      check_assignment_or_regexp(:unordered_list, UnorderedListRegexp)
    end

    def strip_unordered_list_tag
      @line.sub(UnorderedListRegexp, "")
    end

    OrderedListRegexp = /^\s*\d+(\.|\))\s+/

    def ordered_list?
      check_assignment_or_regexp(:ordered_list, OrderedListRegexp)
    end

    DefinitionListRegexp = /^\s*-\s*.+::.+/

    def definition_list?
      check_assignment_or_regexp(:definition_list, DefinitionListRegexp)
    end

    def strip_ordered_list_tag
      @line.sub(OrderedListRegexp, "")
    end

    # Extracts meaningful text and excludes org-mode markup,
    # like identifiers for lists or headings.
    def output_text
      return strip_ordered_list_tag if ordered_list?
      return strip_unordered_list_tag if unordered_list?
      return @line.sub(InlineExampleRegexp, "") if inline_example?
      return line
    end

    def plain_text?
      not metadata? and not blank? and not plain_list?
    end

    def table_row?
      # for an org-mode table, the first non-whitespace character is a
      # | (pipe).
      check_assignment_or_regexp(:table_row, /^\s*\|/)
    end

    def table_separator?
      # an org-mode table separator has the first non-whitespace
      # character as a | (pipe), then consists of nothing else other
      # than pipes, hyphens, and pluses.

      check_assignment_or_regexp(:table_separator, /^\s*\|[-\|\+]*\s*$/)
    end

    # Checks if this line is a table header. 
    def table_header?
      @assigned_paragraph_type == :table_header
    end

    def table?
      table_row? or table_separator? or table_header?
    end

    IncludeSrcRegexp = /^\s*#\+INCLUDE: (.+)\s+(?:src|example)(?:\s+(\S+))?/
    def include_src?
      ret = (@line.upcase =~ IncludeSrcRegexp)
      @include_file, @include_lang = $1, $2 if ret
      ret
    end
    attr_reader :include_file, :include_lang

    BlockRegexp = /^\s*#\+(BEGIN|END)_(\w*)/i

    def begin_block?
      @line =~ BlockRegexp && $1.upcase == "BEGIN"
    end

    def end_block?
      @line =~ BlockRegexp && $1.upcase == "END"
    end

    def block_type
      $2.upcase if @line =~ BlockRegexp
    end

    def code_block_type?
      block_type.upcase =~ /^(EXAMPLE|SRC)$/
    end

    InlineExampleRegexp = /^\s*:/

    # Test if the line matches the "inline example" case:
    # the first character on the line is a colon.
    def inline_example?
      check_assignment_or_regexp(:inline_example, InlineExampleRegexp)
    end

    InBufferSettingRegexp = /^#\+(\w+):\s*(.*)$/

    # call-seq:
    #     line.in_buffer_setting?         => boolean
    #     line.in_buffer_setting? { |key, value| ... }
    #
    # Called without a block, this method determines if the line
    # contains an in-buffer setting. Called with a block, the block
    # will get called if the line contains an in-buffer setting with
    # the key and value for the setting.
    def in_buffer_setting?
      return false if @assigned_paragraph_type && @assigned_paragraph_type != :comment
      if block_given? then
        if @line =~ InBufferSettingRegexp
          yield $1, $2
        end
      else
        @line =~ InBufferSettingRegexp
      end
    end

    # Determines the paragraph type of the current line.
    def paragraph_type
      return :include_src if include_src?
      return :blank if blank?
      return :horizontal_rule if horizontal_rule?
      return :ordered_list if ordered_list?
      return :unordered_list if unordered_list?
      return :metadata if metadata?
      return :comment if comment?
      return :table_separator if table_separator?
      return :table_row if table_row?
      return :table_header if table_header?
      return :inline_example if inline_example?
      return :paragraph
    end

    def self.to_textile(lines)
      output = ""
      output_buffer = TextileOutputBuffer.new(output)
      Parser.translate(lines, output_buffer)
    end

    ######################################################################
    private

    # This function is an internal helper for determining the paragraph
    # type of a line... for instance, if the line is a comment or contains
    # metadata. It's used in routines like blank?, plain_list?, etc.
    #
    # What's tricky is lines can have assigned types, so you need to check
    # the assigned type, if present, or see if the characteristic regexp
    # for the paragraph type matches if not present.
    # 
    # call-seq:
    #     check_assignment_or_regexp(assignment, regexp) => boolean
    #
    # assignment:: if the paragraph has an assigned type, it will be
    #              checked to see if it equals +assignment+.
    # regexp::     If the paragraph does not have an assigned type,
    #              the contents of the paragraph will be checked against
    #              this regexp.
    def check_assignment_or_regexp(assignment, regexp)
      return @assigned_paragraph_type == assignment if @assigned_paragraph_type
      return @line =~ regexp
    end
  end                           # class Line
end                             # module Orgmode
