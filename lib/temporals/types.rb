class Temporal
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

      def normalize(word)
        word = word.capitalize
        order.include?(word) ? word : (translations.has_key?(word) ? translations[word] : nil)
      end
    end

    attr_reader :name, :ord
    alias :to_s :name
    alias :inspect :to_s

    def initialize(word)
      @name = word.is_a?(String) ? self.class.normalize(word) : self.class.order[word]
      @ord  = self.class.order.index(@name)
    end

    def <=>(other)
      ord <=> other.ord
    end
    def ==(other)
      ord == other.ord && name == other.name
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
      'Sun' => 'Sunday',
      'Mo' => 'Monday',
      'Mon' => 'Monday',
      'Tu' => 'Tuesday',
      'Tue' => 'Tuesday',
      'Tues' => 'Tuesday',
      'Wed' => 'Wednesday',
      'Thu' => 'Thursday',
      'Thur' => 'Thursday',
      'Thurs' => 'Thursday',
      'Fri' => 'Friday',
      'Sat' => 'Saturday'
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

  class Set
    def set
      @set ||= []
    end

    def [](key)
      instance_variable_get(:"@#{key}")
    end

    def initialize(*args)
      # @set = args.select {|e| e.is_a?(Temporal) || e.is_a?(Range)}
      @set = args.select {|e| e.is_a?(Temporal)}
    end
  end
  class Union < Set
    def initialize(*args)
      @type = 'UNION'
      super
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
      if other.is_a?(Temporal::Union)
        set.length == other.length && set.length.times { |i| return false unless set[i].eql? other[i] }
      else
        # what else can we compare to?
        raise "Comparison of Temporal::Union with something different (#{other.class.name})."
      end
    end

    def to_natural
      set.inject([]) {|a,tp| a << tp.to_natural}.join(' and ')
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
