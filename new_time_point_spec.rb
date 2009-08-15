require 'rubygems'
require 'spec'
require "#{File.dirname(__FILE__)}/new_time_point"

describe TimePoint do
  it "1st And 4th Thursdays Of March And April 5-6:30pm And March 16th - 24th At 2-2:30pm" do
    TimePoint.parse("1st-2nd And 4th Thursdays Of March And April 5-6:30pm And March 16th - 24th At 2-2:30pm")
  end
end
