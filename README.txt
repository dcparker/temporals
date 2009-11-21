= temporals

* Homepage: http://dcparker.github.com/temporals
* Code: http://github.com/dcparker/temporals

== DESCRIPTION:

"We could develop some interpreter that would be able to parse and process a range of expressions that we might want to deal with. This would be quite flexible, but also pretty hard" (Martin Fowler, http://martinfowler.com/apsupp/recurring.pdf). Temporals is a Ruby parser for just that.

== FEATURES:

Temporals can parse the following expressions:

  * "2-4pm every thursday"
  * "2:30-3p every mon and wed and 3-3:30 on friday"
  * "Thursdays in 2009 and 9 January 2009"
  * "Third Wednesday and Thursday Aug at 3pm"
  * "2pm Fridays in January 2009 and Thursdays in 2009"
  * "1st Thursdays at 4-5pm and First - Fourth of March at 2-3:30pm"
  * "1st-2nd and last Thursdays of March and April 5-6:30pm and March 16th - 24th at 2-2:30pm"
  * ...and probably more that you are going to waste your time thinking of.

Temporals is NOT GUARANTEED to parse anything you give it. It has a limited, though rather large and flexible, vocabulary.
If you come across something that doesn't parse properly, please write a spec test for it and send it to me: gems@behindlogic.com.

== PROBLEMS:

* Should add support for "4th of the month" or "4th month"

== SYNOPSIS:

Temporals works to follow the true spirit of the TimePoint pattern -- the idea that every expression of time in fact has a certain level of intended precision. For example, if I say "March 5, 2000", I simply mean any time within that day -- all day. However, if I say "2:05pm March 5, 2000", I mean any second within that specific minute. But if I say "2:00pm Fridays" I really mean every Friday, and that expression is precise to the day-of-week and to the hour and minute, but the second, week, month, or year don't matter.
The main usage of Temporals, as it currently has been built for, is Temporals.parse and Temporals#include?. Here are several examples:

Example Expressions:
	# All day Tuesday, every week
	  t1 = Temporals.parse('Tuesday')
	
	# Every Feb 24, all day long
	  t2 = Temporals.parse("February 24th")
	
	# Feb 24 in 2001, all day long
	  t3 = Temporals.parse("24 February 2001")
	
	# every Thursday in 2009, and the 9th of January 2009 too
	  t4 = Temporals.parse("9 January 2009 and Thursday 2009")
	
	# default duration of ONE of the most specific piece mentioned: 2-3pm every
	# friday in January of '09, and also all day every thursday all year in 2009
	  t5 = Temporals.parse("2pm Fridays in January 2009 and Thursdays in 2009")

	# first thursday of every month, forever, from 4 to 5 pm;
	# also 2 to 3:30 pm on the 1st, 2nd, 3rd, and 4th of March (every year!)
	  t6 = Temporals.parse("1st Thursdays at 4-5pm and 1st - 4th of March at 2pm")
	
	# you can figure this one out for yourself... Then figure out how the parsing knows exactly what this means! :P
	  t7 = Temporals.parse("1st-2nd and 4th Thursdays of March and April 5-6:30pm and March 16th - 24th at 2-2:30pm")
	
More methods available (referencing some of the above examples):
	t5.include?(Time.parse('2009-02-05 19:00:00')) => true
	t5.include?(Time.parse('2009-01-09 2:31pm')) => true
	t5.include?(Time.parse('February 5, 2010')) => false
	t5.include?(Time.parse('January 16, 2007')) => false
	t6.occurrances_on_day(Time.parse('2009-04-02')) => [{:start_time=>Thu Apr 02 16:00:00 2009, :end_time=>Thu Apr 02 17:00:00 2009}, {:start_time=>Thu Apr 02 14:00:00 2009, :end_time=>Thu Apr 02 15:30:00 2009}]
	t7.occurs_on_day?(Time.parse('2009-03-05')) => true

== REQUIREMENTS:

* Just Ruby!

== INSTALL

* gem install temporals -s http://gemcutter.org

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
