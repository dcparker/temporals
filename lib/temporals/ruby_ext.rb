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
        v.in?(iv)
      else
        if iv.to_s =~ /^\d+$/ && v.to_s =~ /^\d+$/
          iv.to_i == v.to_i
        else
          puts "Comparing #{iv} with #{v}" if $DEBUG
          iv == v
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
  def wday_last
    'last' if day.to_i + 7 > Date.new(year, month, -1).day
  end
end
class DateTime
  include WdayOrd
end
class Time
  include WdayOrd
end
