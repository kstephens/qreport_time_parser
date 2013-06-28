require 'time'
require 'rational'

module Qreport
  class TimeParser
    class Error < ::Exception
      class Syntax < self
        attr_accessor :position, :description
      end
    end

    attr_accessor :input, :result, :now, :debug

    def initialize
      @input = ''
      @unit_for_now = { :today => :day, :t => nil }
      @debug = false # true
      @token = nil
      @token_stack = [ ]
      @taken_tokens = [ ]
    end

    def parse str
      @input_orig = str.dup
      @input = str.dup
      @pos = 0
      @result = p_start
      @result = @result.value if @result.respond_to?(:value)
      @result
    end

    def _p_start
      # debugger
      p_range or
      p_time_expr or
      raise Error
    end

    def _p_range
      if p_between and a = p_time_expr and p_and and b = p_time_expr
        TimeRange.new(a, b)
      end
    end

    def _p_between
      token.type == :range &&
        token.value == :between &&
        take_token.value
    end

    def _p_and
      token.type == :logical and
        token.value == :and and
        take_token.value
    end

    def _p_time_expr
      case
      when v = p_numeric_relative
        v
      when v = p_time
        v
      when v = p_time_or_date_relative
        v
      when (r = p_relation) && (v = p_time_expr)
        v += r
      else
        return nil
      end

      if (op = p_operation) &&
          (interval = p_interval)
        case op
        when :+
          v += interval
        when :-
          v -= interval
        else
          raise Error, op
        end
      end

      v
    end

    # 10 sec before now
    # 10 sec ago
    def _p_numeric_relative
      if (interval = p_interval)
        case 
        when (direction = p_relation) && (time = p_time_expr)
          time + (interval * direction)
        when (direction = p_relative)
          TimeWithUnit.new(now, interval) + (interval * direction)
        end
      end
    end
    
    # 10 secs|day
    def _p_interval
      case token.value
      when Numeric 
        amount = take_token.value
        case
        when TimeInterval === token.value
          interval = take_token.value
          interval *= amount
        end
      when TimeInterval
        interval = take_token.value
      end
    end

    # before|after|since
    def _p_relation
      token.type == :relation && 
        take_token.value
    end

    # ago
    def _p_relative
      token.type == :relative && 
        take_token.value
    end

    # + interval
    def _p_operation
      token.type == :operation && 
        take_token.value
    end

    def _p_time
      TimeWithUnit === token.value && 
        take_token.value
    end

    def _p_time_or_date_relative
      case
      when tr = _p_time_relative
        dr = _p_date_relative
      when dr = _p_date_relative
        tr = _p_time_relative
      else
        return nil
      end

      tr ||= dr
      tr = tr.dup
      if tr && dr && tr != dr
         tr.merge!(dr)
      end

      unit = tr.unit
      t = p_time_expr || now
      # debugger
      tr.merge!(t)
      t = TimeWithUnit.new(tr.to_time, unit)
      # $stderr.puts "  tr = #{tr.inspect} dr = #{dr.inspect} => t = #{t.inspect}"
      t
    end

    # 12pm|12:30a|12:34:56pm
    def _p_time_relative
      if token.type == :time_relative && TimeRelative === token.value
        tr = take_token.value
      end
    end

    # 2001/01|2001-02-20
    def _p_date_relative
      if token.type == :date_relative && TimeRelative === token.value
        tr = take_token.value
      end
    end

    def restore_tokens_on_failure!(sel)
      restore = true
      (@taken_tokens_stack ||= [ ]) << @taken_tokens
      @taken_tokens = [ ]

      result = yield

      # $stderr.puts "  #{sel.inspect} taken_tokens = #{@taken_tokens.inspect}"
      restore = false if result

      result

    ensure
      if restore && ! @taken_tokens.empty?
        $stderr.puts "  #{sel.inspect} restoring tokens #{@taken_tokens.inspect}" if @debug
        @taken_tokens.reverse.each do | t |
          push_token! t
        end 
      end
      @taken_tokens = @taken_tokens_stack.pop
    end

    def method_missing sel, *args, &blk
      if ! block_given? && args.empty? && sel.to_s =~ /^p_/
        result = nil
        if @debug
          @p_depth ||= 0 
          $stderr.puts "  #{' ' * @p_depth} #{sel} ... | #{token.inspect} #{token.value.inspect}"
          @p_depth += 1
        end
        restore_tokens_on_failure!(sel) do
          result = send(:"_#{sel}", *args, &blk)
        end
        if @debug
          @p_depth -= 1
          $stderr.puts "  #{' ' * @p_depth} #{sel} => #{result.inspect} | #{token.inspect}"
        end
        result
      else
        super
      end
    end

    ##############################################################

    def token
      @token ||= 
        (@token_stack.first ? @token_stack.shift : lex)
    end

    def take_token
      t = token
      @taken_tokens << t
      @token = nil
      t
    end

    def push_token! token
      if @token
        @token_stack.unshift @token 
        $stderr.puts "push_token! #{@token.inspect}" if @debug
      end
      @token = token
      $stderr.puts "push_token! #{@token.inspect}" if @debug
      self
    end

    def lex
      debug = @debug
      type = value = nil
      @input.sub!(/\A(\s+)/, '')
      pre_whitespace = $1
      @pos += pre_whitespace.size if pre_whitespace
      # $stderr.puts "  @input = #{@input.inspect[0, 20]}..."; debugger
      case @input
      when ''
        return EOS
      when /\A(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(-[\d:]+)?)\b/ # iso8601
        value = TimeWithUnit.new(Time.parse($1), nil)
      when /\A(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(\.\d+)?(\s+[-+]?[\d]+)?)\b/ # Time#to_s
        value = TimeWithUnit.new(Time.parse($1), nil)
      when /\A(year\s+(\d+))/i
        year = $2 && $2.to_i
        value = TimeRelative.new
        value.year = year
        type = :date_relative
      when /\A((\d{4})(?:([-\/])(0?[1-9]|1[0-2])(?:\3([0-2][0-9]|3[01]))?))\b/i
               year = $2 && $2.to_i
                         sep = $3
                               mon = $4 && $4.to_i
                                                     day = $5 && $5.to_i
        value = TimeRelative.new
        value.year = year
        value.mon = mon
        value.day = day
        type = :date_relative
      when /\A((0[1-9]|1[0-2]|[1-9])(?:[-\/](0[1-9]|[1-2][0-9]|3[01]|[1-9])))\b/i
               mon = $2 && $2.to_i
                                       day = $3 && $3.to_i
        value = TimeRelative.new
        value.mon = mon
        value.day = day
        type = :date_relative
        # debug = true
      when /\A((0?[1-9]|1[0-2])(?::([0-5][0-9])(?::([0-5][0-9]|60))?)\s*(am?|pm?)?)\b/i
        hour = $2.to_i
        min = $3 && $3.to_i
        sec = $4 && $4.to_i
        meridian = ($5 || '').downcase
        hour = 0 if hour == 12
        hour += 12 if meridian.index('p')
        value = TimeRelative.new
        value.hour = hour
        value.min = min
        value.sec = sec
        type = :time_relative
      when /\A(\d\d?)([\/-])(\d\d\d\d)\b/i
        mon = $1 && $1.to_i
        sep = $2
        year = $3 && $3.to_i
        value = TimeRelative.new
        value.year = year
        value.mon = mon
        type = :date_relative
      when /\A((0?[1-9]|1[0-2])\s*(am?|pm?))\b/i
        hour = $2.to_i
        meridian = ($3 || '').downcase
        hour = 0 if hour == 12
        hour += 12 if meridian.index('p')
        value = TimeRelative.new
        value.hour = hour
        type = :time_relative
      when /\A([-+]?\d+\.\d*|\.\d+)/
        value = $1.to_f
        type = :number
      when /\A([-+]?\d+)/
        value = $1.to_i
        type = :number
      when /\A(\+|\-|plus\b|minus\b|in\b)/i
        value = $1.downcase.to_sym
        value = @@operation_alias[value] || value
        type = :operation
      when /\A(today|now|t)\b/i
        value = TimeWithUnit.new(now, unit_for_now($1))
      when /\A(yesterday)\b/i
        value = TimeWithUnit.new(now, :day) - 1
      when /\A(tomorrow)\b/i
        value = TimeWithUnit.new(now, :day) + 1
      when /\A((this)\s+(#{TimeUnit::UNIT_REGEXP}))\b/io
        value = TimeWithUnit.new(now, $3)
      when /\A((previous|last|next)\s+(#{TimeUnit::UNIT_REGEXP}))\b/io
        value = TimeWithUnit.new(now, $3) + TimeInterval.new($2, $3)
      when /\A((#{TimeUnit::UNIT_REGEXP})s?)\b/io
        value = TimeInterval.new(1, $2)
      when /\A((ago))\b/i
        value = $1.downcase.to_sym
        value = @@direction_alias[value]
        type = :relative
      when /\A((before|after|from|since))\b/i
        value = $1.downcase.to_sym
        value = @@direction_alias[value]
        type = :relation
      when /\A(between)\b/i
        value = $1.downcase.to_sym
        type = :range
      when /\A(and|or)\b/i
        value = $1.downcase.to_sym
        type = :logical
      else
        desc = describe_current_parse_position
        err = Error::Syntax.new("syntax error at position #{@pos}: #{desc.inspect}")
        err.position = @pos
        err.description = desc
        raise err
      end
      token = $1
      pos = @pos
      @input[0, token.size] = ''
      @pos += token.size
      token.extend(Token)
      token.pos = pos
      token.pre = pre_whitespace
      token.value = value
      token.type = type
      $stderr.puts "  token => #{token.inspect}" if debug
      token
    end

    def describe_current_parse_position
      s = @input_orig.dup
      s[@pos, 0] = " |^| "
      s
    end

    @@operation_alias = {
      :plus => :+,
      :minus => :-,
      :in => :+,
    }

    @@direction_alias = {
      :ago => -1,
      :before => -1,
      :after => 1,
      :from => 1,
      :since => 1,
      :later => 1,
    }

    def now
      @now ||= Time.now
    end

    def unit_for_now name
      name = name.to_sym
      @unit_for_now[name]
    end

    module Token
      attr_accessor :value, :type, :pre, :pos
      def inspect
        "#<Token #{@type.inspect} #{super} #{@pos} #{@value.inspect}>"
      end

      def with_pre
        @pre.to_s + self
      end
    end

    EOS = Object.new
    EOS.extend(Token)
    def EOS.inspect
      'EOS'
    end

    module TimeUnit
      attr_reader :unit

      def new *args
        self.class.new *args
      end

      def normalize!
        case @unit
        when nil, Symbol
        when String
          @unit = @unit.downcase.to_sym
          @unit = @@unit_alias[@unit] || @unit
        when TimeInterval, TimeWithUnit
          @unit = @unit.unit
        else
          raise ArgumentError, @unit.inspect
        end
        self
      end

      @@unit_alias = {
        :second => :sec,
        :s => :sec,
        :minute => :min,
        :min => :min,
        :m => :min,
        :hr => :hour,
        :h => :hour,
        :d => :day,
        :w => :week,
        :mo => :mon,
        :month => :mon,
        :mth => :mon,
        :yr => :year,
        :y => :year,
      }

      # in seconds
      @@unit_interval = {
        nil => 1,
        :sec => 1,
        :min => 60,
        :hour => 60 * 60,
        :day => 60 * 60 * 24, # + 1 leap second
        :week => 60 * 60 * 24 * 7,
        :mon => (60 * 60 * 24) * 31,
        :year => (60 * 60 * 24) * 365, # + 1 leap day
        :decade => (60 * 60 * 24) * 3650,
        :century => (60 * 60 * 24) * 36500,
        :millenium => (60 * 60 * 24) * 365000,
      }

      def unit_multiplier unit = @unit
        @@unit_interval[unit] || 1
      end
 
      UNIT_REGEXP = 
        (@@unit_interval.keys + 
         @@unit_alias.keys + 
         @@unit_alias.values).
        uniq.
        map{|x| x.to_s}.
        reject{|x| x.empty?}.
        sort{|a, b| b.size <=> a.size} * '|'
      # $stderr.puts "UNIT_REGEXP = #{UNIT_REGEXP}"

      def unit_interval
        @unit_interval ||=
          TimeInterval.new(1, @unit)
      end
    end

    class TimeInterval
      include TimeUnit
      include Comparable
      attr_reader :amount

      def initialize amount, unit
        @amount, @unit = amount, unit
        normalize!
      end

      def to_unit! unit
        @amount *= unit_multiplier(unit).to_r / unit_multipler
        @unit = unit
        normalize!
        self
      end

      def + amount
        case x
        when Numeric
          new(@amount + x, @unit)
        when TimeInterval
          new(@amount.to_sec + x.to_sec, :second)
        else
          raise TypeError, x.class.to_s
        end
      end

      def - amount
        case x
        when Numeric
          new(@amount - x, @unit)
        when TimeInterval
          new(@amount.to_sec - x.to_sec, :second)
        else
          raise TypeError, x.class.to_s
        end
      end

      def * x
        case x
        when Numeric
          new(@amount * x, @unit)
        else
          raise TypeError, x.class.to_s
        end
      end

      def / x
        case x
        when Numeric
          new(@amount / x, @unit)
        when TimeInterval
          @amount.to_sec / x.to_sec
        else
          raise TypeError, x.class.to_s
        end
      end

      def normalize!
        @unit = nil if Float === @amount

        super

        case @amount
        when String, Symbol
          @amount = 
            case @amount.to_s
            when /\A(?:this)\b/i
              0
            when /\A(?:last|previous)\b/i
              -1
            when /\A(?:next|after)\b/i
              1
            else
              raise ArgumentError, amount.inspect
            end
        end

        self
      end

      def to_sec
        @to_sec ||=
          @amount * unit_multiplier
      end

      def <=> x
        case x
        when TimeInterval
          to_sec <=> x.to_sec
        when Numeric
          to_sec <=> x
        else
          raise TypeError, x.inspect
        end
      end
    end

    class TimeRelative
      include TimeUnit
      SLOTS = [ :year, :mon, :day, :hour, :min, :sec, :zone ].freeze
      attr_accessor *SLOTS

      def unit
        case 
        when Float === @sec
          nil
        when @sec
          :sec
        when @min
          :min
        when @hour
          :hour
        when @day
          :day
        when @mon
          :mon
        when @year
          :year
        else
          nil
        end
      end

      def merge! x
        unless self.class === x
          x = x.to_time if x.respond_to?(:to_time)
        end
        @year ||= x.year
        @mon ||= x.mon
        @day ||= x.day
        @hour ||= x.hour
        @min ||= x.min
        @sec ||= x.sec
        @zone ||= x.zone
        self
      end

      def to_s
        str = ''

        [ [ '',  @year, 4 ],
          [ '-', @mon,  2 ],
          [ '-', @day,  2 ],
          [ 'T', @hour, 2 ],
          [ ':', @min,  2 ],
          [ ':', @sec,  2 ],
          [ '-', @zone,   ],
        ].each do | sep, val, size |
          str << sep << (size ? (val ? "%0#{size}d" % val : '?' * size) : val).to_s
        end

        str
      end

      def inspect
        "#<#{self.class} #{to_s}>"
      end

      def from_time! t
        merge! t
      end

      def to_time
        Time.send(@zone == 'UTC' ? :utc : :local, 
                  @year || 0, @mon || 1, @day || 1, @hour || 0, @min || 0, @sec || 0)
      end
    end

    class TimeWithUnit
      include TimeUnit
      include Comparable
      attr_reader :time

      def initialize time, unit
        @time, @unit = time, unit
        normalize!
      end

      def + amount
        # debugger
        case amount
        when Numeric
          amount = TimeInterval.new(amount, @unit)
        end
        raise TypeError, amount.to_s unless TimeInterval === amount
        new(@time + amount.to_sec, 
            [ unit_interval, amount.unit_interval ] )
      end

      def - x
        case x
        when Numeric
          x = TimeInterval.new(x, @unit)
        end
        case x
        when TimeInterval
          new(@time - x.to_sec,
              [ unit_interval, x.unit_interval ])
        when TimeWithUnit, ::Time
          TimeInterval.new(@time.to_f - x.to_f, :second)
        else
          raise TypeError, x.inspect
        end
      end

      def to_time
        @time
      end

      def to_f
        @time.to_f
      end

      def <=> x
        case x
        when TimeWithUnit
          @time <=> x.to_time
        else
          @time <=> x
        end
      end

      def normalize!
        case @unit
        when Array
          @unit = @unit.reduce{|a, b| a < b ? a : b}
        end

        super

        case @time
        when nil
          return
        when ::Time
        when String
          @time = ::Time.parse(@time)
        when Numeric
          @time = ::Time.utc(@time)
        when ::Date
          @time = @time.to_time
        when TimeWithUnit
          @time = @time.to_time
        else
          raise TypeError, @time.inspect
        end

        # debugger
        args = 
          case @unit
          when nil
            return self
          when :decade
            [ @time.year % 10 * 10, 1, 1, 0, 0, 0 ]
          when :century
            [ @time.year % 100 / 100, 1, 1, 0, 0, 0 ]
          when :millenium
            [ @time.year % 1000 / 1000, 1, 1, 0, 0, 0 ]
          else
            @@unit_args[@unit] or
              raise ArgumentError, @unit.inspect
          end
        if args.any? { | x | Symbol === x }
          args = args.map do | x | 
            x = @time.send(x) if Symbol === x
            x
          end
        end
        # $stderr.puts "  @time #{inspect} => "
        # $stderr.puts "    args = #{args.inspect}"
        @time = @time.class.send(zone_method, *args)
        # $stderr.puts "    #{inspect}"
        self
      end

      @@unit_args = {
        :sec =>
          [ :year, :mon, :day, :hour, :min, :sec ],
        :min =>
          [ :year, :mon, :day, :hour, :min, 0 ],
        :hour =>
          [ :year, :mon, :day, :hour, 0, 0 ],
        :day =>
          [ :year, :mon, :day, 0,     0, 0 ],
        :week =>
          [ :year, :mon, :day, 0,     0, 0 ],
        :mon =>
          [ :year, :mon, 1,    0,     0, 0 ],
        :year =>
          [ :year, 1,      1,    0,     0, 0 ],
      }

      UTC = 'UTC'.freeze

      def zone_method
        case @time.zone
        when UTC
          :utc
        else
          :local
        end
      end

      def inspect
        "#<#{self.class} #{to_s}>"
      end

      def to_s
        "#{@unit.inspect} #{@time && @time.iso8601(6)}"
      end

      def to_TimeRange
        TimeRange.new(self, self + unit_interval)
      end

      def to_range
        to_TimeRange.to_range
      end
    end

    class TimeRange
      include Comparable
      attr_reader :a, :b

      def initialize a, b
        @a = a
        @b = b
      end

      def inspect
        "#<{self.class] #{to_s}>"
      end

      def min
        a <= b ? a : b
      end

      def max
        a <= b ? b : a
      end

      def to_s
        "#{a} ... #{b}"
      end

      def to_range
        if a <= b
          (a.to_time ... b.to_time)
        else
          (b.to_time ... a.to_time)
        end
      end
    end

    def self.examples
      now = ::Time.parse("2011-03-10T15:10:37.981304-06:00")
      examples = {
        "now" => "nil 2011-03-10T15:10:37.981304-06:00",
        now.to_s => "nil 2011-03-10T15:10:37.000000-06:00",
        "2011-03-10 15:10:37.981304 -0600" => "nil 2011-03-10T15:10:37.981304-06:00",
        "today" => ":day 2011-03-10T00:00:00.000000-06:00",
        "tomorrow" => ":day 2011-03-11T00:00:00.000000-06:00",
        "yesterday" => ":day 2011-03-09T00:00:00.000000-06:00",
        "10 days ago" => ":day 2011-02-28T00:00:00.000000-06:00",
        "10 s ago" => ":sec 2011-03-10T15:10:27.000000-06:00",
        "3 days before today" => ":day 2011-03-07T00:00:00.000000-06:00",
        "5 days after today" => ":day 2011-03-15T00:00:00.000000-05:00",
        "5 days before now" => "nil 2011-03-05T15:10:37.981304-06:00",
        "3 days before this minute" => ":min 2011-03-07T15:10:00.000000-06:00",
        "5 days before yesterday" => ":day 2011-03-04T00:00:00.000000-06:00",
        "2 days before 50 hours after tomorrow" => ":hour 2011-03-11T02:00:00.000000-06:00",
        "1pm" => ":hour 2011-03-10T13:00:00.000000-06:00",
        "12:30pm" => ":min 2011-03-10T12:30:00.000000-06:00",
        "9:20am tomorrow" => ":min 2011-03-11T09:20:00.000000-06:00",
        "6am 3 days from yesterday" => ":hour 2011-03-12T06:00:00.000000-06:00",
        "2001/01" => ":mon 2001-01-01T00:00:00.000000-06:00",
        "2001-01" => ":mon 2001-01-01T00:00:00.000000-06:00",
        # "01/2001" => ":mon 2001-01-01T00:00:00.000000-06:00",
        "01/2001" => "#<Qreport::TimeParser::Error::Syntax: syntax error at position 2: \"01 |^| /2001\">",
        "2001/02/03 12:23pm" => ":min 2001-02-03T12:23:00.000000-06:00",
        "12/31 12:59pm" => ":min 2011-12-31T12:59:00.000000-06:00",
        "12/31 last year" => ":day 2010-12-31T00:00:00.000000-06:00",
        "12:59:59pm 12/31 next year" => ":sec 2012-12-31T12:59:59.000000-06:00",
        "1:23:45pm 1/2 in 2 years" => ":sec 2013-01-01T13:23:45.000000-06:00",
        "2011-03-10T15:10:37-06:00" => "nil 2011-03-10T15:10:37.000000-06:00",
        "2011-03-10T15:10:37.981304-06:00" => "nil 2011-03-10T15:10:37.981304-06:00",
        "2011-03-10T15:10:37-06:00 plus 10 sec" => ":sec 2011-03-10T15:10:47.000000-06:00",
        "2011-03-10T15:10:37.981304-06:00 - 2 weeks" => "nil 2011-02-24T15:10:37.981304-06:00",
        "now minus 2.5 weeks" => "nil 2011-03-10T15:10:35.481304-06:00",
        "t - 10 sec" => ":sec 2011-03-10T15:10:27.000000-06:00",
        "123.45 sec ago" => "nil 2011-03-10T15:08:34.531303-06:00",
        "year 2010" => ":year 2010-01-01T00:00:00.000000-06:00",
        "between 12:45pm and 1:15pm" => ":min 2011-03-10T12:45:00.000000-06:00 ... :min 2011-03-10T13:15:00.000000-06:00",
        "before 1:23pm tomorrow" => ":min 2011-03-11T13:22:00.000000-06:00",
        "this minute" => ":min 2011-03-10T15:10:00.000000-06:00",
        "last hour"     => ":hour 2011-03-10T14:00:00.000000-06:00",
        "previous hour" => ":hour 2011-03-10T14:00:00.000000-06:00",
        "last day"   => [ ":day 2011-03-09T00:00:00.000000-06:00", ":day 2011-03-09T00:00:00.000000-06:00 ... :day 2011-03-10T00:00:00.000000-06:00" ],
        "previous day" => ":day 2011-03-09T00:00:00.000000-06:00",
        "  2001-01 + 1234 ajsdkfsd hours" => "#<Qreport::TimeParser::Error::Syntax: syntax error at position 17: \"  2001-01 + 1234  |^| ajsdkfsd hours\">"
      }
      examples[:now] = now
      examples
    end

  end # class
end # module



