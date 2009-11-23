require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/temporals'

describe Temporal do
  it "Thursday" do
    t = Temporal.parse('Thursday')
    t.should_not be_nil
    t.to_natural.should eql('Thursday')
  end
  
  it "1st-2nd and last Thursdays of March and April 5-6:30pm and March 16th - 24th at 2-2:30pm" do
    t = Temporal.parse("1st-2nd and last Thursdays of March and April 5-6:30pm and March 16th - 24th at 2-2:30pm")
    t.include?(Time.parse('2009-03-05 17:54')).should eql(true)
    t.include?(Time.parse('2009-03-05 18:24')).should eql(true)
    t.include?(Time.parse('2009-03-05 18:30')).should eql(true)
    t.include?(Time.parse('2009-03-05 18:31')).should eql(false)
    t.include?(Time.parse('2009-04-26 18:31')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-03-04')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-03-11')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-03-25')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-04-01')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-04-08')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-04-22')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-03-05')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-03-12')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-03-26')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-04-02')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-04-09')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-04-30')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-03-06')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-03-13')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-03-27')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-04-03')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-04-10')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-04-24')).should eql(false)
    t.occurrances_on_day(Time.parse('2009-04-23')).length.should eql(0)
    t.occurrances_on_day(Time.parse('2009-04-30')).length.should eql(1)
  end

  it "1st Thursdays at 4-5pm and First - Fourth of March at 2-3:30pm" do
    t = Temporal.parse("1st Tuesdays at 4-5pm and First - Fourth of March at 2-3:30pm")
    t.occurs_on_day?(Time.parse('2009-04-07')).should eql(true)
    t.occurrances_on_day(Time.parse('2009-03-01')).length.should eql(1)
    t.occurrances_on_day(Time.parse('2009-03-03')).length.should eql(2)
    t.occurrances_on_day(Time.parse('2009-05-05')).length.should eql(1)
    t.occurrances_on_day(Time.parse('2009-05-12')).length.should eql(0)
  end

  it "should FAIL on 1st Thursdays at 4-5pm and First - Fourth of March and April at 2-3:30pm" do
    lambda {
      # This could be grouped in two different ways. The first is more likely what is meant, but
      # the second is possible so the patterns are not set up to match the first option for sure.
      #  (1st Thursdays at 4-5pm) and ((First - Fourth of March and April) at 2-3:30pm)
      #  (1st Thursdays at 4-5pm) and (First - Fourth of March) and (April at 2-3:30pm)
      Temporal.parse("1st Thursdays at 4-5pm and First - Fourth of March and April at 2-3:30pm")
    }.should raise_error(RuntimeError, "Could not parse Temporal Expression: check to make sure it is clear and has only one possible meaning.")
  end

  it "2pm Tuesdays" do
    t = Temporal.parse("2pm Tuesdays")
    t.occurs_on_day?(Time.parse('2009-04-28')).should eql(true)
    t.occurrances_on_day(Time.parse('2009-04-28')).length.should eql(1)
    t.occurrances_on_day(Time.parse('2009-04-28'))[0][:start_time].should eql(Time.parse('2009-04-28 2:00pm'))
    t.occurrances_on_day(Time.parse('2009-04-28'))[0][:end_time].should eql(Time.parse('2009-04-28 3pm'))
    t.include?(Time.parse('2009-04-21 14:52')).should eql(true)
    t.include?(Time.parse('2009-04-21 14:59:59')).should eql(true)
  end

  it "2:30pm Tuesdays" do
    t = Temporal.parse("2:30pm Tuesdays")
    t.occurs_on_day?(Time.parse('2009-04-28')).should eql(true)
    t.occurrances_on_day(Time.parse('2009-04-28')).length.should eql(1)
    t.occurrances_on_day(Time.parse('2009-04-28'))[0][:start_time].should eql(Time.parse('2009-04-28 2:30pm'))
    t.occurrances_on_day(Time.parse('2009-04-28'))[0][:end_time].should eql(Time.parse('2009-04-28 2:31pm'))
    t.include?(Time.parse('2009-04-21 14:30')).should eql(true)
    t.include?(Time.parse('2009-04-21 14:30:59')).should eql(true)
    t.include?(Time.parse('2009-04-21 14:31')).should eql(true)
    t.include?(Time.parse('2009-04-21 14:31:01')).should eql(false)
  end

  it "2:30-3p every mon and wed and 3-3:30 on friday" do
    t = Temporal.parse("2:30-3p every mon and wed and 3-3:30 on friday")
    t.occurs_on_day?(Time.parse('2009-11-20')).should eql(true)
    t.occurs_on_day?(Time.parse('2009-11-19')).should eql(false)
    t.occurs_on_day?(Time.parse('2009-11-18')).should eql(true)
    t.occurrances_on_day(Time.parse('2009-11-20'))[0][:start_time].should eql(Time.parse('2009-11-20 3pm'))
    t.occurrances_on_day(Time.parse('2009-11-18'))[0][:end_time].should eql(Time.parse('2009-11-18 3pm'))
    t.include?(Time.parse('2009-11-20 3:14pm')).should eql(true)
  end

  it "Thursdays in 2009 and 9 January 2009" do
    t = Temporal.parse("Thursdays in 2009 and 9 January 2009")
    t.occurs_on_day?(Time.parse('January 9, 2009')).should eql(true)
    t.occurs_on_day?(Time.parse('November 19, 2009')).should eql(true)
    t.occurs_on_day?(Time.parse('October 19, 2009')).should eql(false)
    t.include?(Time.parse('2009-01-08 3:14pm')).should eql(true)
  end

  it "2pm Fridays in January 2009 and Thursdays in 2009" do
    t = Temporal.parse("2pm Fridays in January 2009 and Thursdays in 2009")
    t.occurs_on_day?(Time.parse('November 19, 2009')).should eql(true)
    t.occurs_on_day?(Time.parse('January 9, 2009')).should eql(true)
    t.occurs_on_day?(Time.parse('October 19, 2009')).should eql(false)
    t.include?(Time.parse('2009-01-08 3:14pm')).should eql(true)
    t.include?(Time.parse('2009-01-09 2:14pm')).should eql(true)
    t.include?(Time.parse('2009-01-09 3:14pm')).should eql(false)
  end
end
