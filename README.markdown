# time_point #

* [http://github.com/dcparker/time_point](http://github.com/dcparker/time_point)

## Description ##

An attempt at a Ruby implementation of [Martin Fowler's TimePoint pattern](http://martinfowler.com/ap2/timePoint.html). It is most certainly lacking some areas (ex. timezone support), but its algorithm for parsing the natural language for recurring time-points is quite powerful.

## Synopsis ##

TimePoint works to follow the true spirit of the TimePoint pattern -- the idea that every expression of time in fact has a certain level of precision intended. For example, if I say "March 5, 2000", I simply mean any time within that day -- all day. However, if I say "2:05pm March 5, 2000", I mean any second within that very specific minute. But if I say "2:00pm Fridays" I really mean every Friday, and that expression is precise to the day-of-week and to the hour and minute, but the second, week, month, or year don't matter.

The main usage of TimePoint, as it currently has been built for, is TimePoint.parse and TimePoint#include?. Here are several examples:

Example Expressions:
	# All day Tuesday, every week
	  t1 = TimePoint.parse('Tuesday')
	
	# Every Feb 24, all day long
	  t2 = TimePoint.parse("February 24th")
	
	# Feb 24 in 2001, all day long
	  t3 = TimePoint.parse("24 February 2001")
	
	# every Thursday in 2009, and the 9th of January 2009 too
	  t4 = TimePoint.parse("9 January 2009 and Thursday 2009")
	
	# default duration of ONE of the most specific piece mentioned: 2-3pm every
	# friday in January of '09, and also all day every thursday all year in 2009
	  t5 = TimePoint.parse("2pm Fridays in January 2009 and Thursdays in 2009")

	# first thursday of every month, forever, from 4 to 5 pm;
	# also 2 to 3:30 pm on the 1st, 2nd, 3rd, and 4th of March (every year!)
	  t6 = TimePoint.parse("1st Thursdays at 4-5pm and 1st - 4th of March at 2-3:30pm")
	
	# you can figure this one out for yourself... Then figure out how the parsing knows exactly what this means! :P
	  t7 = TimePoint.parse("1st-2nd and 4th Thursdays of March and April 5-6:30pm and March 16th - 24th at 2-2:30pm")
	
More methods available (referencing some of the above examples):
	t5.include?(Time.parse('2009-02-05 19:00:00')) => true
	t5.include?(Time.parse('2009-01-09 2:31pm')) => true
	t5.include?(Time.parse('February 5, 2010')) => false
	t5.include?(Time.parse('January 16, 2007')) => false
	t6.occurrances_on_day(Time.parse('2009-04-02')) => [{:start_time=>Thu Apr 02 16:00:00 2009, :end_time=>Thu Apr 02 17:00:00 2009}, {:start_time=>Thu Apr 02 14:00:00 2009, :end_time=>Thu Apr 02 15:30:00 2009}]
	t7.occurs_on_day?(Time.parse('2009-03-05')) => true

## Problems ##

* Does not yet assume an end-time for a time-range when an end-time is not given. This is necessary so that '2pm Fridays' really means '2-3pm Fridays', and '2:30pm Fridays' really means '2:30-2:31pm Fridays'.
* Not yet able to compare two TimePoints.
* Not yet able to serialize a parsed TimePoint back into text.
* Does not yet understand words that reference from today's date, like "Today", "Tomorrow", "Next Week".

## Requirements ##

* Just Ruby!

## Install ##

* [sudo] gem install time_point

## License ##

(The MIT License)

Copyright (c) 2009 BehindLogic <gems@behindlogic.com>

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
