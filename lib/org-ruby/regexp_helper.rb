require 'logger'

module Orgmode

  # = Summary
  # 
  # This class contains helper routines to deal with the Regexp "black
  # magic" you need to properly parse org-mode files.
  #
  # = Key methods
  #
  # * Use +rewrite_emphasis+ to replace org-mode emphasis strings (e.g.,
  #   \/italic/) with the suitable markup for the output.
  #
  # * Use +rewrite_links+ to get a chance to rewrite all org-mode
  #   links with suitable markup for the output.
  #
  # * Use +rewrite_images+ to rewrite all inline image links with suitable
  #   markup for the output.
  class RegexpHelper

    ######################################################################
    # EMPHASIS
    #
    # I figure it's best to stick as closely to the elisp implementation
    # as possible for emphasis. org.el defines the regular expression that
    # is used to apply "emphasis" (in my terminology, inline formatting
    # instead of block formatting). Here's the documentation from org.el.
    #
    # Terminology: In an emphasis string like " *strong word* ", we
    # call the initial space PREMATCH, the final space POSTMATCH, the
    # stars MARKERS, "s" and "d" are BORDER characters and "trong wor"
    # is the body.  The different components in this variable specify
    # what is allowed/forbidden in each part:
    #
    # pre          Chars allowed as prematch.  Line beginning allowed, too.
    # post         Chars allowed as postmatch.  Line end will be allowed too.
    # border       The chars *forbidden* as border characters.
    # body-regexp  A regexp like \".\" to match a body character.  Don't use
    #              non-shy groups here, and don't allow newline here.
    # newline      The maximum number of newlines allowed in an emphasis exp.
    #
    # I currently don't use +newline+ because I've thrown this information
    # away by this point in the code. TODO -- revisit?
    attr_reader   :pre_emphasis
    attr_reader   :post_emphasis
    attr_reader   :border_forbidden
    attr_reader   :body_regexp
    attr_reader   :markers

    attr_reader   :org_emphasis_regexp

    def initialize
      # Set up the emphasis regular expression.
      @pre_emphasis = " \t\\('\""
      @post_emphasis = "- \t.,:!?;'\"\\)"
      @border_forbidden = " \t\r\n,\"'"
      @body_regexp = ".*?"
      @markers = "*/_=~+"
      @logger = Logger.new(STDERR)
      @logger.level = Logger::WARN
      build_org_emphasis_regexp
    end

    # Finds all emphasis matches in a string.
    # Supply a block that will get the marker and body as parameters.
    def match_all(str)
      str.scan(@org_emphasis_regexp) do |match|
        yield $2, $3
      end
    end

    # Compute replacements for all matching emphasized phrases.
    # Supply a block that will get the marker and body as parameters;
    # return the replacement string from your block.
    #
    # = Example
    #
    #   re = RegexpHelper.new
    #   result = re.rewrite_emphasis("*bold*, /italic/, =code=") do |marker, body|
    #       "<#{map[marker]}>#{body}</#{map[marker]}>"
    #   end
    #
    # In this example, the block body will get called three times:
    #
    # 1. Marker: "*", body: "bold"
    # 2. Marker: "/", body: "italic"
    # 3. Marker: "=", body: "code"
    #
    # The return from this block is a string that will be used to
    # replace "*bold*", "/italic/", and "=code=",
    # respectively. (Clearly this sample string will use HTML-like
    # syntax, assuming +map+ is defined appropriately.)
    def rewrite_emphasis(str)
      str.gsub(@org_emphasis_regexp) do |match|
        inner = yield $2, $3
        "#{$1}#{inner}#{$4}"
      end
    end

    ORG_LINK_OR_URL_REGEXP = /
                              (?: # link with text
                               \[\[
                                 ((?:https?|file)[^\]]*)
                               \]\[
                                 ([^\]]*)
                               \]\]
                              )
                               |
                              (?:
                               \[\[ # url link
                                 ((?:https?|file)[^\]]*)
                               \]\]
                              )
                               |
                              (?:((?:https?|file):[^\]\s]*)(\]\])?)/x # bare url
    # = Summary
    #
    # Rewrite org-mode links in a string to markup suitable to the
    # output format.
    #
    # = Usage
    # 
    # Give this a block that expect the link and optional friendly
    # text. Return how that link should get formatted.
    #
    # = Example
    #
    #   re = RegexpHelper.new
    #   result = re.rewrite_links("[[http://www.bing.com]] and [[http://www.hotmail.com][Hotmail]]") do |link, text}
    #       text ||= link
    #       "<a href=\"#{link}\">#{text}</a>"
    #    end
    #
    # In this example, the block body will get called two times. In the
    # first instance, +text+ will be nil (the org-mode markup gives no
    # friendly text for the link +http://www.bing.com+. In the second
    # instance, the block will get text of *Hotmail* and the link
    # +http://www.hotmail.com+. In both cases, the block returns an
    # HTML-style link, and that is how things will get recorded in
    # +result+.
    def rewrite_links(str) #  :yields: link, text
      str.gsub(ORG_LINK_OR_URL_REGEXP) do
        m = Regexp.last_match
        if m[1] && m[2]
          yield m[1], m[2]
        elsif m[3]
          yield m[3], nil
        elsif m[4]
          yield m[4], nil
        else
          m[0]
        end
      end
    end
    
    # Rewrites all of the inline image tags.
    def rewrite_images(str) #  :yields: image_link
      raise "Do not use rewrite_images, use rewrite_links instead!"
    end

    private

    def build_org_emphasis_regexp
      @org_emphasis_regexp = Regexp.new("([#{@pre_emphasis}]|^)\n" +
                                        "(  [#{@markers}]  )\n" + 
                                        "(  [^#{@border_forbidden}]  | " +
                                        "  [^#{@border_forbidden}]#{@body_regexp}[^#{@border_forbidden}]  )\n" +
                                        "\\2\n" +
                                        "([#{@post_emphasis}]|$)\n", Regexp::EXTENDED)
      @logger.debug "Just created regexp: #{@org_emphasis_regexp}"
    end

  end                           # class Emphasis
end                             # module Orgmode
