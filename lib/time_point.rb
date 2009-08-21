require 'date'
require 'time'

class Array
  def includes_sequence?(sequence)
    first_exists = []
    each_index do |i|
      first_exists << i if self[i] == sequence[0]
    end
    first_exists.any? do |i|
      return i if self[i...(i+sequence.length)] == sequence
    end
  end

  def include_value?(v)
    any? do |iv|
      case iv
      when Range || Array
        v.to_i.in?(iv)
      else
        if iv.to_s =~ /^\d+$/ && v.to_s =~ /^\d+$/
          iv.to_i == v.to_i
        else
          iv.to_s == v.to_s
        end
      end
    end
  end
end

class Range
  alias :include_value? :include?
end

class Object
  def value_in?(*arg)
    arg = arg[0] if arg.length == 1 && arg[0].respond_to?(:include_value?)
    arg.include_value?(self)
  end
  def in?(*arg)
    arg = arg[0] if arg.length == 1 && arg[0].respond_to?(:include?)
    arg.include?(self)
  end
  def my_methods
    methods.sort - Object.methods
  end
end

module WdayOrd
  def wday_ord
    (day.to_f / 7).ceil
  end
end
class DateTime
  include WdayOrd
end
class Time
  include WdayOrd
end

class TimePoint
  class ArrayOfRanges < Array
    def self.new(*values)
      n = allocate
      n.push(*values)
      n
    end
  end

  class Classification
    class << self
      attr_reader :order, :translations

      def abbreviations
        @abbreviations ||= translations.inject({}) do |h,(k,v)|
          h[v] = k unless h.has_key?(v) && h[v].length < k.length
          h
        end
      end
    end
  end
  
  class WDay < Classification
    @order = %w(Sunday Monday Tuesday Wednesday Thursday Friday)
    @translations = {
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
      'Saturdays' => 'Saturday'
    }
  end
  class Month < Classification
    @order = %w(January February March April May June July August September October November December)
    @translations = {
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
      'Dec' => 'December'
    }
  end

  # These are in a specific order
  CommonPatterns = [
    'ord range ord',
    'ord union ord',
    'wday range wday',
    'wday union wday',
    'month ord',
    'ord wday',
    'ord month timerange',
    'month_ord timerange',
    'month union month',
    'month range month',
    'ord_wday month',
    'ord_wday timerange',
    'ord_wday_month timerange'
  ]
  CommonPatternActions = {
    'ord range ord' => lambda {|words,i|
      words[i][:ord] = (words[i][:ord].to_i..words[i+2][:ord].to_i)
      words.slice!(i+1,2)
    },
    'ord union ord' => lambda {|words,i|
      words[i][:ord] = ArrayOfRanges.new(words[i][:ord], words[i+2][:ord])
      words.slice!(i+1,2)
    },
    'wday range wday' => lambda {|words,i|
      words[i][:wday] = (words[i][:wday].to_i..words[i+2][:wday].to_i)
      words.slice!(i+1,2)
    },
    'wday union wday' => lambda {|words,i|
      words[i][:wday] = ArrayOfRanges.new(words[i][:wday], words[i+2][:wday])
      words.slice!(i+1,2)
    },
    'month ord' => lambda {|words,i|
      words[i][:type] = 'month_ord'
      words[i][:ord] = words[i+1][:ord]
      words.slice!(i+1,1)
    },
    'ord wday' => lambda {|words,i|
      words[i][:type] = 'ord_wday'
      words[i][:wday] = words[i+1][:wday]
      words.slice!(i+1,1)
    },
    'ord month timerange' => lambda {|words,i|
      words[i][:type] = 'month_ord_timerange'
      words[i][:month] = words[i+1][:month]
      words[i][:start_time] = words[i+2][:start_time]
      words[i][:end_time] = words[i+2][:end_time]
      words.slice!(i+1,2)
    },
    'month_ord timerange' => lambda {|words,i|
      words[i][:type] = 'month_ord_timerange'
      words[i][:start_time] = words[i+1][:start_time]
      words[i][:end_time] = words[i+1][:end_time]
      words.slice!(i+1,1)
    },
    'month union month' => lambda {|words,i|
      words[i][:month] = ArrayOfRanges.new(words[i][:month], words[i+2][:month])
      words.slice!(i+1,2)
    },
    'month range month' => lambda {|words,i|
      raise "Not Implemented Yet!"
    },
    'ord_wday month' => lambda {|words,i|
      words[i][:type] = 'ord_wday_month'
      words[i][:month] = words[i+1][:month]
      words.slice!(i+1,1)
    },
    'ord_wday timerange' => lambda {|words,i|
      words[i][:type] = 'ord_wday_timerange'
      words[i][:start_time] = words[i+1][:start_time]
      words[i][:end_time] = words[i+1][:end_time]
      words.slice!(i+1,1)
    },
    'ord_wday_month timerange' => lambda {|words,i|
      words[i][:type] = 'ord_wday_month_timerange'
      words[i][:start_time] = words[i+1][:start_time]
      words[i][:end_time] = words[i+1][:end_time]
      words.slice!(i+1,1)
    }
  }

  BooleanPatterns = [
    'union'
  ]

  BooleanPatternActions = {
    'union' => lambda {|words,i|
      words[i-1] = TimePoint::Union.new(words[i-1], words[i+1])
      words.slice!(i,2)
      puts words.inspect if $DEBUG
    }
  }

  TimeRegexp = '\d{1,2}(?::\d{1,2})?(?:am|pm)'
  WordTypes = {
    :ord => /^(\d+)(?:st|nd|rd|th)?$/i,
    :wday => /^(#{WDay.order.join('|')})s$/i,
    :month => /^#{Month.order.join('|')}$/i,
    :union => /^(?:and)$/i,
    :range => /^(?:-|to|through)$/,
    :timerange => /^(#{TimeRegexp}?)-(#{TimeRegexp})$/i,
    :time => /^#{TimeRegexp}$/i
  }
  
  class << self
    def parse(expression)
      # 1. Normalize the expression
      # TODO: re-create normalize: ' -&| ', 'time-time'
      expression.gsub!(/([\-\&\|])/,' \1 ')
      expression.gsub!(/(#{TimeRegexp}?)\s+-\s+(#{TimeRegexp})/,'\1-\2')

      # 2. Analyze the expression
      words = expression.split(/\s+/)
      puts words.inspect if $DEBUG
      analyzed_expression = words.inject([]) do |a,word|
        a << case word
        when WordTypes[:ord]
          {:type => 'ord', :ord => $1}
        when WordTypes[:wday]
          {:type => 'wday', :wday => $1}
        when WordTypes[:month]
          {:type => 'month', :month => word}
        when WordTypes[:union]
          {:type => 'union'}
        when WordTypes[:range]
          {:type => 'range'}
        when WordTypes[:timerange]
          {:type => 'timerange', :start_time => $1, :end_time => $2}
        when WordTypes[:time]
          {:type => 'time', :time => word}
        end
      end.compact
      def analyzed_expression.collect_types
        collect {|e| e[:type]}
      end

      # 3. Combine common patterns
      puts analyzed_expression.inspect if $DEBUG
      puts analyzed_expression.collect_types.inspect if $DEBUG

      something_was_modified = true
      while something_was_modified
        something_was_modified = false
        before_length = analyzed_expression.length
        CommonPatterns.each do |pattern|
          while i = analyzed_expression.collect_types.includes_sequence?(pattern.split(/ /))
            CommonPatternActions[pattern].call(analyzed_expression,i)
          end
        end
        after_length = analyzed_expression.length
        something_was_modified = true if before_length != after_length
      end
      
      puts analyzed_expression.inspect if $DEBUG
      puts analyzed_expression.collect_types.inspect if $DEBUG

      # What remains should be simply sections of boolean logic
      # 4. Parse boolean logic
      analyzed_expression.each_index do |i|
        analyzed_expression[i] = TimePoint.new(analyzed_expression[i]) unless ['union', 'range'].include? analyzed_expression[i][:type]
      end

      BooleanPatterns.each do |pattern|
        while i = analyzed_expression.collect_types.includes_sequence?(pattern.split(/ /))
          BooleanPatternActions[pattern].call(analyzed_expression,i)
          break if analyzed_expression.length == 1
        end
      end

      return analyzed_expression[0]
    end
  end

  def initialize(options)
    options.each do |key,value|
      instance_variable_set(:"@#{key}", value)
    end
  end

  def [](key)
    instance_variable_get(:"@#{key}")
  end

  def start_pm?
    if @start_time =~ /(am|pm)$/ || @end_time =~ /(am|pm)$/
      $1 == 'pm'
    else
      nil
    end
  end

  def include?(datetime)
    return false unless occurs_on_day?(datetime)
    if @type =~ /timerange/
      test_date = datetime.strftime("%Y-%m-%d")
      test_start_time = Time.parse("#{test_date} #{@start_time}#{start_pm? ? 'pm' : 'am'}")
      test_end_time = Time.parse("#{test_date} #{@end_time}")
      puts "TimeRange: date:#{test_date} test_start:#{test_start_time} test_end:#{test_end_time} <=> #{datetime}" if $DEBUG
      return false unless datetime.between?(test_start_time, test_end_time)
    end
    return true
    puts "#{datetime} Included!" if $DEBUG
  end

  def occurs_on_day?(datetime)
    puts "#{datetime} IN? #{inspect}" if $DEBUG
    puts "Correct month? #{Month.order[datetime.month-1].inspect}==#{@month.inspect} : #{Month.order[datetime.month-1].value_in?(@month)}" if @type =~ /month/ if $DEBUG
    return false if @type =~ /month/ && !Month.order[datetime.month-1].value_in?(@month)
    if @type =~ /ord_wday/
      puts "Weekday: #{WDay.order[datetime.wday].inspect} in? #{@wday.inspect} == #{WDay.order[datetime.wday].value_in?(@wday)}" if $DEBUG
      return false unless WDay.order[datetime.wday].value_in?(@wday)
      puts "WeekdayOrd: #{datetime.wday_ord} in? #{@ord.inspect} == #{datetime.wday_ord.value_in?(@ord)}" if $DEBUG
      return false unless datetime.wday_ord.value_in?(@ord)
    end
    if @type =~ /month_ord/
      puts "Day #{datetime.day} == #{@ord.inspect} >> #{datetime.day.value_in?(@ord)}" if $DEBUG
      return false unless datetime.day.value_in?(@ord)
    end
    # puts "Type: #{@type}" if $DEBUG
    # case
    # when @type == 'ord_wday_month'
    #   return true
    # when @type == 'ord_wday_month_timerange'
    #   return true
    # when @type == 'ord_wday_timerange'
    #   return true
    # when @type == 'month_ord_timerange'
    # end
    puts "Occurs on #{datetime}!" if $DEBUG
    return true
  end

  def occurrances_on_day(date)
    occurs_on_day?(date) ? [{:start_time => start_time(date), :end_time => end_time(date)}] : []
  end

  def start_time(date=nil)
    if date
      Time.parse("#{date.strftime("%Y-%m-%d")} #{@start_time}#{start_pm? ? 'pm' : 'am'}")
    else
      @start_time
    end
  end
  def end_time(date=nil)
    if date
      Time.parse("#{date.strftime("%Y-%m-%d")} #{@end_time}")
    else
      @end_time
    end
  end

  class Union
    def set
      @set ||= []
    end

    def initialize(*args)
      # @set = args.select {|e| e.is_a?(TimePoint) || e.is_a?(Range)}
      @set = args.select {|e| e.is_a?(TimePoint)}
      # @set = args
    end

    def include?(other)
      set.any? {|tp| tp.include?(other)}
    end

    def occurs_on_day?(other)
      set.any? {|tp| tp.occurs_on_day?(other)}
    end

    def occurrances_on_day(other)
      set.inject([]) {|a,tp| a.concat(tp.occurrances_on_day(other)); a}
    end

    def eql?(other)
      if other.is_a?(TimePoint::Union)
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
end
