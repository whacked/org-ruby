require File.join(File.dirname(__FILE__), %w[spec_helper])

describe Orgmode::RegexpHelper do
  it "should recognize simple markup" do
    e = Orgmode::RegexpHelper.new
    total = 0
    e.match_all("/italic/") do |border, string|
      border.should eql("/")
      string.should eql("italic")
      total += 1
    end
    total.should eql(1)

    total = 0
    borders = %w[* / ~]
    strings = %w[bold italic verbatim]
    e.match_all("This string contains *bold*, /italic/, and ~verbatim~ text.")\
    do |border, str|
      border.should eql(borders[total])
      str.should eql(strings[total])
      total += 1
    end
    total.should eql(3)
  end

  it "should not get confused by links" do
    e = Orgmode::RegexpHelper.new
    total = 0
    # Make sure the slashes in these links aren't treated as italics
    e.match_all("[[http://www.bing.com/twitter]]") do |border, str|
      total += 1
    end
    total.should eql(0)
  end

  it "should correctly perform substitutions" do
    e = Orgmode::RegexpHelper.new
    map = {
      "*" => "strong",
      "/" => "i",
      "~" => "pre"
    }
    n = e.rewrite_emphasis("This string contains *bold*, /italic/, and ~verbatim~ text.") do |border, str|
      "<#{map[border]}>#{str}</#{map[border]}>"
    end
    n.should eql("This string contains <strong>bold</strong>, <i>italic</i>, and <pre>verbatim</pre> text.")
  end

  it "should allow link rewriting (url link)" do
    e = Orgmode::RegexpHelper.new
    str = e.rewrite_links("[[http://www.bing.com]]") do |link,text|
      text ||= link
      "\"#{text}\":#{link}"
    end
    str.should eql("\"http://www.bing.com\":http://www.bing.com")
  end

  it "should allow url rewriting (bare url)" do
    e = Orgmode::RegexpHelper.new
    str = e.rewrite_links("http://www.bing.com") do |link,text|
      text ||= link
      "\"#{text}\":#{link}"
    end
    str.should eql("\"http://www.bing.com\":http://www.bing.com")
  end

  it "should allow url rewriting (url with text)" do
    e = Orgmode::RegexpHelper.new
    str = e.rewrite_links("[[http://www.bing.com][Bing]]") do |link,text|
      text ||= link
      "\"#{text}\":#{link}"
    end
    str.should eql("\"Bing\":http://www.bing.com")
  end

  it "should allow url rewriting (no url)" do
    e = Orgmode::RegexpHelper.new
    str = e.rewrite_links("Bing") do |link,text|
      text ||= link
      "\"#{text}\":#{link}"
    end
    str.should eql("Bing")
  end
end                             # describe Orgmode::RegexpHelper
