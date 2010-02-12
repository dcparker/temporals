class Temporal
  TimeRegexp = '\d{1,2}(?::\d\d)?(?::\d{1,2})?(?:[ap]m?)?'
  WordOrds = %w(first second third fourth fifth)
  WordTypes = {
    :ord => /^([1-3]?\d)(?:st|nd|rd|th)?$/i, # Should be able to distinguish
    :word_ord => /^(first|second|third|fourth|fifth|last)$/i,
    :wday => /^(#{(WDay.order + WDay.translations.keys).join('|')})s?$/i,
    :month => /^#{(Month.order + Month.translations.keys).join('|')}$/i,
    :year => /^([09]\d|\d{4})$/, # A year will be either 2 digits starting with a 9 or a 0, or 4 digits.
    :union => /^(?:and)$/i,
    :range => /^(?:-|to|through)$/i,
    :timerange => /^(#{TimeRegexp}?)-(#{TimeRegexp})$/i,
    # :from => /^from$/i,
    # :to => /^to$/i,
    # :between => /^between$/i
  }

  # These are in a specific order
  CommonPatterns = [
    'ord range ord',
    'ord union ord',
    'year range year',
    'year union year',
    'wday range wday',
    'wday union wday',
    # 'timerange union timerange', # Not quite figured out yet, I'd need to implement new code into the question methods.
    'month ord',
    'ord month',
    'ord wday',
    'month_ord timerange',
    'month union month',
    'month range month',
    'ord_wday month',
    'ord_wday timerange',
    'ord_wday_month timerange',
    'timerange wday',
    'month_ord year',
    'month year',
    'wday year',
    "wday_timerange month",
    "wday_timerange year",
    "wday_timerange month_year"
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
    'year range year' => lambda {|words,i|
      words[i][:year] = (words[i][:year].to_i..words[i+2][:year].to_i)
      words.slice!(i+1,2)
    },
    'year union year' => lambda {|words,i|
      words[i][:year] = ArrayOfRanges.new(words[i][:year], words[i+2][:year])
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
    # 'timerange union timerange' => lambda {|words,i|
    #   words[i][:wday] = ArrayOfRanges.new(words[i][:wday], words[i+2][:wday])
    #   words.slice!(i+1,2)
    # },
    'month ord' => lambda {|words,i|
      words[i][:type] = 'month_ord'
      words[i][:ord] = words[i+1][:ord]
      words.slice!(i+1,1)
    },
    'ord month' => lambda {|words,i|
      words[i][:type] = 'month_ord'
      words[i][:month] = words[i+1][:month]
      words.slice!(i+1,1)
    },
    'ord wday' => lambda {|words,i|
      words[i][:type] = 'ord_wday'
      words[i][:wday] = words[i+1][:wday]
      words.slice!(i+1,1)
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
      # raise "Not Implemented Yet!"
      words[i][:month] = (words[i][:month]..words[i+2][:month])
      words.slice!(i+1,2)
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
    'timerange wday' => lambda {|words,i|
      words[i][:type] = 'wday_timerange'
      words[i][:wday] = words[i+1][:wday]
      words.slice!(i+1,1)
    },
    'ord_wday_month timerange' => lambda {|words,i|
      words[i][:type] = 'ord_wday_month_timerange'
      words[i][:start_time] = words[i+1][:start_time]
      words[i][:end_time] = words[i+1][:end_time]
      words.slice!(i+1,1)
    },
    'month_ord year' => lambda {|words,i|
      words[i][:type] = 'ord_month_year'
      words[i][:year] = words[i+1][:year]
      words.slice!(i+1,1)
    },
    'wday year' => lambda {|words,i|
      words[i][:type] = 'wday_year'
      words[i][:year] = words[i+1][:year]
      words.slice!(i+1,1)
    },
    'month year' => lambda {|words,i|
      words[i][:type] = 'month_year'
      words[i][:year] = words[i+1][:year]
      words.slice!(i+1,1)
    },
    'wday_timerange month' => lambda {|words,i|
      words[i][:type] = 'wday_timerange_month'
      words[i][:month] = words[i+1][:month]
      words.slice!(i+1,1)
    },
    'wday_timerange year' => lambda {|words,i|
      words[i][:type] = 'wday_timerange_year'
      words[i][:year] = words[i+1][:year]
      words.slice!(i+1,1)
    },
    'wday_timerange month_year' => lambda {|words,i|
      words[i][:type] = 'wday_timerange_month_year'
      words[i][:month] = words[i+1][:month]
      words[i][:year] = words[i+1][:year]
      words.slice!(i+1,1)
    }
  }

  BooleanPatterns = [
    'union'
  ]

  BooleanPatternActions = {
    'union' => lambda {|words,i|
      words[i-1] = Temporal::Union.new(words[i-1], words[i+1])
      words.slice!(i,2)
      puts "Boolean-connected: " + words.inspect if $DEBUG
    }
  }
end
