class Temporal
  class << self
    def parse(expression)
      # Make a copy of the passed in string, rather than mutate it
      expression = expression.to_s.dup
            
      puts "Parsing expression: #{expression.inspect}" if $DEBUG
      normalized_expression = normalize_expression(expression)
      analyzed_expression = analyze_normalized_expression(normalized_expression)
      combine_common_patterns!(analyzed_expression)
      parse_boolean_logic!(analyzed_expression)

      # This is how we know if the expression couldn't quite be figured out. 
      # It should have been condensed down to a single Temporal or Temporal::Set
      if analyzed_expression.length > 1
        raise RuntimeError, "Could not parse Temporal Expression: check to make sure it is clear and has only one possible meaning."
      else
        analyzed_expression[0]
      end
    end
    
    private
      def normalize_expression(expression)
        # TODO: re-create normalize: ' -&| ', 'time-time'
        expression.gsub!(/\s+/,' ').gsub!(/([\-\&\|])/,' \1 ')
        expression.gsub!(/(#{TimeRegexp}?) +- +(#{TimeRegexp})/,'\1-\2')
        expression.gsub!(/in ([09]\d|\d{4})/) {|s|
          y = $1
          y.length == 2 ? (y =~ /^0/ ? '20'+y : '19'+y) : y
        }
        expression.gsub!(/(^| )(#{TimeRegexp})( |$)/i) {|s|
          b = $1
          time = $2
          a = $3
          if s =~ /[:m]/ # If it really looks like a lone piece of time, it'll have either a am/pm or a ':' in it.
            # Converting a floating time into a timerange that spans the appropriate duration
            puts "Converting Time to TimeRange: #{time.inspect}" if $DEBUG
            # Figure out what precision we're at
            newtime = time + '-'
            if time =~ /(\d+):(\d+)([ap]m?|$)?/
              end_hr = $1.to_i
              end_mn = $2.to_i + 1
              if end_mn > 59
                end_mn -= 60
                end_hr += 1
              end
              end_hr -= 12 if end_hr > 12
              newtime += "#{end_hr}:#{end_mn}#{$3}" # end-time is 1 minute later
            elsif time =~ /(\d+)([ap]m?|$)?/
              end_hr = $1.to_i + 1
              end_hr -= 12 if end_hr > 12
              newtime += "#{end_hr}#{$2}" # end-time is 1 hour later
            end
            puts "Converted! #{newtime}" if $DEBUG
            b+newtime+a
          else
            s
          end
        }
        puts "Normalized expression: #{expression.inspect}" if $DEBUG
        expression
      end
      
      def analyze_normalized_expression(normalized_expression)
        words = normalize_expression(normalized_expression).split(/\s+/)
        puts words.inspect if $DEBUG
        analyzed_expression = words.inject([]) do |a,word|
          a << case word
          when WordTypes[:ord]
            {:type => 'ord', :ord => $1}
          when WordTypes[:word_ord]
            ord = WordOrds.include?(word.downcase) ? WordOrds.index(word.downcase)+1 : 'last'
            puts "WordOrd: #{ord}" if $DEBUG
            {:type => 'ord', :ord => ord}
          when WordTypes[:wday]
            {:type => 'wday', :wday => WDay.normalize($1)}
          when WordTypes[:year]
            {:type => 'year', :year => word}
          when WordTypes[:month]
            {:type => 'month', :month => Month.normalize(word)}
          when WordTypes[:union]
            {:type => 'union'}
          when WordTypes[:range]
            {:type => 'range'}
          when WordTypes[:timerange]
            # determine and inject am/pm
            start_at = $1
            end_at = $2
            start_at_p = $1 if start_at =~ /([ap])m?$/
            end_at_p = $1 if end_at =~ /([ap])m?$/
            start_hr = start_at.split(/:/)[0].to_i
              start_hr = '0' if start_hr == '12' # this is used only for > & < comparisons, so converting it to 0 makes everything easier.
            end_hr = end_at.split(/:/)[0].to_i
            if start_at_p && !end_at_p
              # If end-time is a lower hour number than start-time, then we've crossed noon or midnight, and the end-time a/pm should be opposite.
              end_at = end_at + (start_hr <= end_hr ? start_at_p : (start_at_p=='a' ? 'p' : 'a'))
            elsif end_at_p && !start_at_p
              # If end-time is a lower hour number than start-time, then we've crossed noon or midnight, and the start-time a/pm should be opposite.
              start_at = start_at + (start_hr <= end_hr ? end_at_p : (end_at_p=='a' ? 'p' : 'a'))
            elsif !end_at_p && !start_at_p
              # If neither had am/pm attached, assume am if after 7, pm if 12 or before 7.
              start_at_p = (start_hr < 8 ? 'p' : 'a')
              start_at = start_at + start_at_p
              # If end-time is a lower hour number than start-time, then we've crossed noon or midnight, and the end-time a/pm should be opposite.
              end_at = end_at + (start_hr <= end_hr ? start_at_p : (start_at_p=='a' ? 'p' : 'a'))
            end
            start_at += 'm' unless start_at =~ /m$/
            end_at += 'm' unless end_at =~ /m$/
            {:type => 'timerange', :start_time => start_at, :end_time => end_at}
          end
        end.compact
        def analyzed_expression.collect_types
          collect {|e|
            puts "E: #{e.inspect}" if $DEBUG
            e[:type]
            }
        end
        analyzed_expression
      end
      
      def combine_common_patterns!(analyzed_expression)
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
        analyzed_expression
      end
      
      def parse_boolean_logic!(analyzed_expression)
        analyzed_expression.each_index do |i|
          analyzed_expression[i] = Temporal.new(analyzed_expression[i]) unless analyzed_expression[i][:type].in?('union', 'range')
        end

        BooleanPatterns.each do |pattern|
          while i = analyzed_expression.collect_types.includes_sequence?(pattern.split(/ /))
            BooleanPatternActions[pattern].call(analyzed_expression,i)
            break if analyzed_expression.length == 1
          end
        end
        
        analyzed_expression
      end
  end
end
