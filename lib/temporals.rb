
require 'date'
require 'time'
require 'temporals/ruby_ext'
require 'temporals/types'
require 'temporals/patterns'
require 'temporals/parser'

class Temporal
  VERSION = '2.0.0'

  def initialize(options)
    options.each do |key,value|
      instance_variable_set(:"@#{key}", value)
    end
  end

  def [](key)
    instance_variable_get(:"@#{key}")
  end

  def start_pm?
    if @start_time =~ /([ap])m$/ || @end_time =~ /([ap])m$/
      $1 == 'p'
    else
      nil
    end
  end

  def include?(datetime)
    return false unless occurs_on_day?(datetime)
    if @type =~ /timerange/
      test_date = datetime.strftime("%Y-%m-%d")
      test_start_time = Time.parse("#{test_date} #{@start_time.gsub(/([ap]m)$/,'')}#{start_pm? ? 'pm' : 'am'}")
      test_end_time = Time.parse("#{test_date} #{@end_time}")
      test_end_time = test_end_time+59 if test_end_time == test_start_time # If they're equal, they are assumed to be to the minute precision
      puts "TimeRange: date:#{test_date} test_start:#{test_start_time} test_end:#{test_end_time} <=> #{datetime}" if $DEBUG
      return false unless datetime.between?(test_start_time, test_end_time)
    end
    return true
    puts "#{datetime} Included!" if $DEBUG
  end

  def occurs_on_day?(datetime)
    puts "#{datetime} IN? #{inspect}" if $DEBUG
    if @type =~ /month/
      puts "Month #{Month.new(datetime.month-1).inspect} in? #{@month.inspect} >> #{Month.new(datetime.month-1).value_in?(@month)}" if $DEBUG
      return false unless Month.new(datetime.month-1).value_in?(@month)
    end
    if @type =~ /ord_wday/
      puts "Weekday: #{WDay.new(datetime.wday).inspect} in? #{@wday.inspect} >> #{WDay.new(datetime.wday).value_in?(@wday)}" if $DEBUG
      return false unless WDay.new(datetime.wday).value_in?(@wday)
      puts "WeekdayOrd: #{datetime.wday_ord} in? #{@ord.inspect} >> #{datetime.wday_ord.value_in?(@ord)}" if $DEBUG
      puts "WeekdayLast: #{datetime.wday_last} in? #{@ord.inspect} >> #{datetime.wday_last.value_in?(@ord)}" if $DEBUG
      return false unless datetime.wday_ord.value_in?(@ord) || datetime.wday_last.value_in?(@ord)
    end
    if @type =~ /month_ord/
      puts "Day #{datetime.day} == #{@ord.inspect} >> #{datetime.day.value_in?(@ord)}" if $DEBUG
      return false unless datetime.day.value_in?(@ord)
    end
    if @type =~ /year/
      puts "Year #{datetime.year} == #{@year.inspect} >> #{datetime.year.value_in?(@year)}" if $DEBUG
      return false unless datetime.year.value_in?(@year)
    end
    if @type =~ /wday/
      puts "Weekday: #{WDay.new(datetime.wday).inspect} in? #{@wday.inspect} == #{WDay.new(datetime.wday).value_in?(@wday)}" if $DEBUG
      return false unless WDay.new(datetime.wday).value_in?(@wday)
    end
    puts "Occurs on #{datetime}!" if $DEBUG
    return true
  end

  def occurrances_on_day(date)
    occurs_on_day?(date) ? [{:start_time => start_time(date), :end_time => end_time(date)}] : []
  end

  def start_time(date=nil)
    if date
      @start_time.sub!(/^(\d+)/,'\1:00') if @start_time =~ /^(\d+)[^:]/
      puts "#{date.strftime("%Y-%m-%d")} #{@start_time}" if $DEBUG
      Time.parse("#{date.strftime("%Y-%m-%d")} #{@start_time}")
    else
      @start_time
    end
  end
  def end_time(date=nil)
    if date
      @end_time.sub!(/^(\d+)/,'\1:00') if @end_time =~ /^(\d+)[^:]/
      puts "#{date.strftime("%Y-%m-%d")} #{@end_time}" if $DEBUG
      Time.parse("#{date.strftime("%Y-%m-%d")} #{@end_time}")
    else
      @end_time
    end
  end

  def to_natural
    @type.split(/_/).collect {|w|
      case w
      # when 'ord'
      #   if @ord.respond_to?(:to_natural)
      #     @ord.to_natural('ord')
      #   end
      #   if @ord.is_a?(Range)
      #     @ord.begin + 'th-' + @ord.end
      #   elsif @ord.is_a?(Array)
      #     
      #   else
      #     @ord + 'th'
      #   end
      when 'dummy'
      else
        instance_variable_get('@'+w)
      end
    }.join(' ')
  end
end

Temporals = Temporal
