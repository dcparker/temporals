require 'rubygems'
require 'spec'
require "#{File.dirname(__FILE__)}/time_point"

describe Time do
  it "should report the correct week number" do
    Time.parse('Jan 7, 2009').week.should eql(1)
    Time.parse('Jan 17, 2009').week.should eql(2)
    Time.parse('Jan 18, 2009').week.should eql(3)
    Time.parse('Jan 25, 2009').week.should eql(4)
    Time.parse('Jan 31, 2009').week.should eql(4)
  end
end

describe TimePoint do
  it "should parse a simple day of the week" do
    tuesday = TimePoint.parse('Tuesday')
    tuesday.should include(Time.parse('Tues, Jan 13, 2009'))
    tuesday.should_not include(Time.parse('Wed, Jan 14, 2009'))
    tuesday.should include(Time.parse('Tues, Feb 3, 2009'))
    tuesday.should_not include(Time.parse('Wed, Feb 2, 2009'))
  end

  it "should parse more complex TimePoints (A)" do
    tp = TimePoint.parse("February 24th")
    tp.should include(Time.parse('February 24, 2006'))
    tp.should include(Time.parse('February 24, 2010'))
    tp.should_not include(Time.parse('February 23, 2007'))
  end

  it "should parse more complex TimePoints (B)" do
    tp = TimePoint.parse("24 February 2001")
    tp.should include(Time.parse('February 24, 2001'))
    tp.should include(Time.parse('2001-02-24 16:00:01'))
    tp.should_not include(Time.parse('2001-02-23 16:00:01'))
    tp.should_not include(Time.parse('2001-03-24 08:25:43'))
    tp.should_not include(Time.parse('2002-02-24 10:30:01'))
  end

  it "should parse more complex TimePoints (C)" do
    tp = TimePoint.parse("9 January 2009 and Thursday 2009")
    tp.should include(Time.parse('February 5, 2009'))
    tp.should include(Time.parse('January 9, 2009'))
    tp.should_not include(Time.parse('February 5, 2010'))
    tp.should_not include(Time.parse('January 9, 2007'))
  end

  it "should parse more complex TimePoints (D)" do
    tp = TimePoint.parse("2pm Fridays in January 2009 and Thursdays in 2009")
    tp.should include(Time.parse('2009-02-05 19:00:00'))
    tp.should include(Time.parse('2009-01-09 14:31:00'))
    tp.should_not include(Time.parse('February 5, 2010'))
    tp.should_not include(Time.parse('January 16, 2007'))
  end

  it "should parse a TimePointIntersection" do
    TimePoint.parse('Tuesday and Thursday').should eql(TimePointIntersection.new(TimePoint.new(:wday => 3), TimePoint.new(:wday => 5)))
  end

  it "should translate and expand before parsing" do
    TimePoint.parse('T&Th Feb').should eql(TimePoint.parse('Tuesday and Thursday in February'))
  end
end

describe TimePointIntersection do
  it "should deal with a simple set of TimePoints correctly" do
    tue_thur = TimePointIntersection.new(TimePoint.parse('Tuesday'), TimePoint.parse('Thursday'))
    tue_thur.should_not include(Time.parse('Tues, Jan 5, 2009'))
    tue_thur.should include(Time.parse('Wed, Jan 6, 2009'))
    tue_thur.should_not include(Time.parse('Thurs, Jan 7, 2009'))
    tue_thur.should include(Time.parse('Fri, Jan 8, 2009'))
  end
end
