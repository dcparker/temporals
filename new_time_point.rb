# TODO: finish common patterns


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

  CommonPatterns = [
    'ord union ord',
    'ord range ord',
    'month ord',
    'wday union wday',
    'wday range wday'
  ]
  CommonPatternActions = {
    'ord union ord' => lambda {|words,i|
      words[i][:ord] = ArrayOfRanges.new(words[i][:ord], words[i+2][:ord])
      words.slice!(i+1,2)
    },
    'ord range ord' => lambda {|words,i|
      words[i][:ord] = (words[i][:ord].to_i..words[i+2][:ord].to_i)
      words.slice!(i+1,2)
    },
    'month ord' => lambda {|words,i|
      words[i][:type] = 'month_ord'
      words[i][:ord] = words[i+1][:ord]
      words.slice!(i+1,1)
    },
    'wday union wday' => lambda {|words,i|
      
    },
    'wday range wday' => lambda {|words,i|
      
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
        if i = analyzed_expression.collect_types.includes_sequence?(pattern.split(/ /))
          CommonPatternActions[pattern].call(analyzed_expression,i)
        end
      end
      
      puts analyzed_expression.inspect
      puts analyzed_expression.collect_types.inspect
      
    end
  end
end
