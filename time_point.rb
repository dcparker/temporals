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
  PRECISION_ORDER = [:second, :minute, :hour, :wday, :week, :month, :year]
  PRECISION_SCALE_ORDER = [:date, :secondly, :minutely, :hourly, :daily, :weekly, :monthly, :yearly]

  DAYS = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  WEEKS = [nil, 'First', 'Second', 'Third', 'Fourth', 'Fifth']
  MONTHS = [nil, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']

  TRANSLATIONS = {
    'S' => 'Sunday',
    'M' => 'Monday',
    'T' => 'Tuesday',
    'W' => 'Wednesday',
    'Th' => 'Thursday',
    'F' => 'Friday',
    'Sa' => 'Saturday',
    'Sundays' => 'Sunday',
    'Mondays' => 'Monday',
    'Tuesdays' => 'Tuesday',
    'Wednesdays' => 'Wednesday',
    'Thursdays' => 'Thursday',
    'Fridays' => 'Friday',
    'Saturdays' => 'Saturday',
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
    tp = allocate

    # Highly Magical PARSE Action!!
    # or, maybe not quite. :/
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
      set.length == other.length && set.length.times { |i| return false unless set[i].eql? other[i] }
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
