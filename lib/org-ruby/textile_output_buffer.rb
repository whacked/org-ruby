require 'stringio'

module Orgmode

  class TextileOutputBuffer < OutputBuffer

    def initialize(output)
      super(output)
      @add_paragraph = false
    end

    def push_mode(mode, opts={})
      super(mode, opts)
      @output << "bc.. " if mode_is_code(mode)
    end

    def pop_mode(mode = nil)
      m = super(mode)
      @add_paragraph = (mode_is_code(m))
      m
    end

    # Maps org markup to textile markup.
    TextileMap = {
      "*" => "*",
      "/" => "_",
      "_" => "_",
      "=" => "@",
      "~" => "@",
      "+" => "+"
    }

    # Handles inline formatting for textile.
    def inline_formatting(input)
      input = @re_help.rewrite_emphasis(input) do |marker, body|
        m = TextileMap[marker]
        "#{m}#{body}#{m}"
      end
      input = @re_help.rewrite_links(input) do |link, text|
        text ||= link
        link = link.gsub(/ /, "%20")
        "\"#{text}\":#{link}"
      end
      input
    end

    # Flushes the current buffer
    def flush!
      @logger.debug "FLUSH ==========> #{@output_type}"
      if (@output_type == :blank) then
        @output << "\n"
      elsif (@buffer.length > 0) then
        if @add_paragraph then
          @output << "p. " if @output_type == :paragraph
          @add_paragraph = false
        end
        @output << "bq. " if current_mode == :blockquote
        @output << "#" * @list_indent_stack.length << " " if @output_type == :ordered_list
        @output << "*" * @list_indent_stack.length << " " if @output_type == :unordered_list
        @output << inline_formatting(@buffer) << "\n"
      end
      clear_accumulation_buffer!
    end


  end                           # class TextileOutputBuffer
end                             # module Orgmode
