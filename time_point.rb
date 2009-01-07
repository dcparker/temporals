require 'time'

class Time
  def to_time
    self
  end

  # Week number.
  # This is obtained by rewinding to the first day of the current week (day - wday) and dividing by 7 (int division), polish by adding 1.
  def week
    ((day - wday) / 7) + 1
  end
end

# Every expression of time that covers only one unit of time can be represented by a TimePoint. "Friday" is a TimePoint that only cares about
# the day-of-week. "This Tuesday 2pm" is a TimePoint that cares about the actual date and the hour. Anytime within 2 o'clock this Tuesday
# would match. However, "2-3pm" is not a single TimePoint because it covers more than one unit (hours) of time. "2-3pm" would be a
# TimePointRange, where there is a begin-TimePoint and an end-TimePoint. "Tuesdays and Thursdays" is also not a single TimePoint, but a
# TimePointSet. A TimePointSet is a set of multiple, unrelated TimePoint's or TimePointRange's.
class TimePoint
  Second = :second
  Minute = :minute
  Hour = :hour
  Day = :day
  WDay = :wday
  Week = :week
  Month = :month
  Year = :year

  # Cycle precision
  Secondly = :secondly
  Minutely = :minutely
  Hourly = :hourly
  Daily = :daily
  Weekly = :weekly
  Monthly = :monthly
  Yearly = :yearly
  # Date precision
  Date = :date

  PRECISION_ORDER = [Second, Minute, Hour, WDay, Week, Month, Year]
  PRECISION_SCALE_ORDER = [Date, Secondly, Minutely, Hourly, Daily, Weekly, Monthly, Yearly]

  DAYS = [nil, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']
  WEEKS = [nil, 'First', 'Second', 'Third', 'Fourth', 'Fifth']
  MONTHS = [nil, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

  TRANSLATIONS = {
    'M' => 'Monday',
    'T' => 'Tuesday',
    'W' => 'Wednesday',
    'Th' => 'Thursday',
    'F' => 'Friday',
    '1o' => 'First',
    '2o' => 'Second',
    '3o' => 'Third',
    '4o' => 'Fourth',
    '5o' => 'Fifth',
    'Jan' => 'January',
    'Feb' => 'February',
    'Mar' => 'March',
    'Apr' => 'April',
    'Jun' => 'June',
    'Jul' => 'July',
    'Aug' => 'August',
    'Sep' => 'September',
    'Oct' => 'October',
    'Nov' => 'November',
    'Dec' => 'December',
    '&' => 'And'
  }

  # These allow a TimePoint to act like a time object, but we don't have to have all of them defined!
  attr_accessor :second, :minute, :hour, :day, :wday, :week, :month, :year
  # TODO: Currently you can blindly set these, but beware because the wday might not match the day/month/year on the real calendar!

  def self.parse(expression)
    # Tuesday => Weekly, WDay precision
    # This Tuesday => Date, WDay precision
    # 2:00 => Daily, Minute precision
    # Tuesday 2:00 => Weekly, Minute precision
    # This Tuesday 2pm => Date, Hour precision
    tp = allocate

    # Highly Magical PARSE Action!!
    # or, not yet. :/
    words = expression.downcase.gsub(/&/,' & ').split(/\s+/).map {|w| TRANSLATIONS[w] || w}
    
    current = tp
    until words.empty?
      word = words.shift.capitalize

      case
      when word =~ /^(\d{1,2})(?:st|nd|rd|th)?$/
        current.day = $1.to_i
      when word =~ /^(\d{4})$/
        current.year = $1.to_i
      when word =~ /^(\d{2})(am|pm)?$/i
        current.hour = $2 == 'pm' ? $1.to_i + 12 : $1.to_i
      when word =~ /^(\d{2}):(\d{2})(am|pm)?$/i
        current.hour = $3 == 'pm' ? $1.to_i + 12 : $1.to_i
        current.minute = $2.to_i
      when word == 'And'
        tp = TimePointSet.new unless tp.is_a?(TimePointSet)
        tp << current
        current = allocate
      when WEEKS.include?(word)
        # like First, Second, Third, Fourth, Fifth
        current.week = WEEKS.index(word)
      when MONTHS.include?(word)
        current.month = MONTHS.index(word)
      when DAYS.include?(word)
        current.wday = DAYS.index(word)
      end

    end
    # *************
    tp << current if tp.is_a?(TimePointSet)

    return tp
  end

  def initialize(options={})
    options.each {|k,v| send("#{k}=",v) if respond_to?("#{k}=")}
  end

  def include?(value)
    # Does the given time, adjusted to my precision, eql me?
    otime = value.to_time
    instance_variables.each do |ivar|
      ivname = ivar.gsub(/@/,'')
      next unless respond_to?(ivname)
      return false unless send(ivname) == otime.send(ivname)
    end
    return true
  end

  def eql?(other)
    if other.is_a?(TimePoint)
      instance_variables.each do |ivar|
        ivname = ivar.gsub(/@/,'')
        next unless respond_to?(ivname)
        return false unless send(ivname) == other.send(ivname)
      end
      return true
    else
      # what else can we compare to?
      raise "Comparison of TimePoint with something different (#{other.class.name})."
    end
  end
end

# Has a begin-TimePoint and an end-TimePoint, and they share the same precision.
class TimePointRange
  attr_accessor :begin_tp, :end_tp
  def initialize(begin_tp, end_tp)
    @begin_tp = begin_tp
    @end_tp = end_tp
  end

  def include?(other)
    begin_tp <= other && end_tp >= other
  end
end

# Just a Set of TimePoint's and TimePointRange's.
class TimePointSet
  def set
    @set ||= []
  end

  def initialize(*args)
    @set = args.select {|e| e.is_a?(TimePoint) || e.is_a?(TimePointRange)}
  end

  def include?(other)
    set.any? {|tp| tp.include?(other)}
  end

  def eql?(other)
    if other.is_a?(TimePointSet)
      set.length == other.length && set.length.times {|i| set[i].eql? other[i]}
    else
      # what else can we compare to?
      raise "Comparison of TimePointSet with something different (#{other.class.name})."
    end
  end

  private
  # Sends all other methods to the set array.
  def method_missing(name, *args, &block)
    if set.respond_to?(name)
      args << block if block_given?
      set.send(name, *args)
    else
      super
    end
  end
end

require 'rubygems'
require 'spec'

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
    tp = TimePoint.parse("Friday 2pm January 2009 and Thursday 2009")
    tp.should include(Time.parse('2009-02-05 19:00:00'))
    tp.should include(Time.parse('2009-01-09 14:31:00'))
    tp.should_not include(Time.parse('February 5, 2010'))
    tp.should_not include(Time.parse('January 16, 2007'))
  end

  it "should parse a TimePointSet" do
    TimePoint.parse('Tuesday and Thursday').should eql(TimePointSet.new(TimePoint.new(:wday => 3), TimePoint.new(:wday => 5)))
  end

  it "should parse a TimePointSet" do
    TimePoint.parse('T&Th February').should eql(TimePoint.parse('Tuesday and Thursday in Feb'))
  end
end

describe TimePointSet do
  it "should deal with a simple set of TimePoints correctly" do
    tue_thur = TimePointSet.new(TimePoint.parse('Tuesday'), TimePoint.parse('Thursday'))
    tue_thur.should_not include(Time.parse('Tues, Jan 5, 2009'))
    tue_thur.should include(Time.parse('Wed, Jan 6, 2009'))
    tue_thur.should_not include(Time.parse('Thurs, Jan 7, 2009'))
    tue_thur.should include(Time.parse('Fri, Jan 8, 2009'))
  end
end
