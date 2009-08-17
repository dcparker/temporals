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
    'month_ord timerange'
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
    'month_ord timerange' => lambda {|words,i|
      words[i][:type] = 'month_ord_timerange'
      words[i][:timerange] = words[i+1][:timerange]
      words.slice!(i+1,1)
    },
    'wday_ord month union month' => lambda {|words,i|
      words[i][:month] = ArrayOfRanges.new(words[i+1][:month], words[i+3][:month])
      words.slice!(i+2,2)
    }
  }

  TimeRegexp = '\d{1,2}(?::\d{1,2})?(?:am|pm)'
  WordTypes = {
    :ord => /^(\d+)(?:st|nd|rd|th)?$/i,
    :wday => /^#{WDay.order.join('|')}$/i,
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
      puts words.inspect
      analyzed_expression = words.inject([]) do |a,word|
        a << case word
        when WordTypes[:ord]
          {:type => 'ord', :ord => $1}
        when WordTypes[:wday]
          {:type => 'wday', :wday => word}
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
      puts analyzed_expression.inspect
      puts analyzed_expression.collect_types.inspect

      CommonPatterns.each do |pattern|
        while i = analyzed_expression.collect_types.includes_sequence?(pattern.split(/ /))
          CommonPatternActions[pattern].call(analyzed_expression,i)
        end
      end
      
      puts analyzed_expression.inspect
      puts analyzed_expression.collect_types.inspect
      
      # What remains should be sections of distinct time-points and boolean logic
      # 4. Parse time-points and boolean logic
      
    end
  end
end
