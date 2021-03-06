require 'time'
require 'rational'

module Qreport
  class TimeParser
    class Error < ::Exception
      attr_accessor :position, :description
      class Syntax < self ; end
    end

    attr_accessor :input, :start, :result, :now, :debug, :unit_for_now

    def initialize start = nil
      @start = start
      @unit_for_now = { :today => :day, :t => :now }
      @debug = false
      # @debug = true
      initialize_copy nil
    end

    def initialize_copy x
      @input = ''
      @token = nil
      @token_stack = [ ]
      @taken_tokens = [ ]
      @pos = @result = nil
    end

    def parse str, start = nil
      _parse str, start || @start
    end

    def _parse str, start
      $stderr.puts "\n  parse #{str.inspect} #{start.inspect}" if @debug
      @input_orig = str.dup
      @input = str.dup
      @pos = 0
      @p_depth = 1
      @result = send(start || :p_default)
      @result = @result.value if @result.respond_to?(:value)
      $stderr.puts "  parse #{str.inspect} #{start.inspect} => #{@result.inspect}\n\n" if @debug
      @result
    end

    def self.def_p name, &blk
      sel = :"p_#{name}"
      _sel = :"_#{sel}"
      define_method _sel, &blk
      define_method sel do
        _wrap_p! sel do
          restore_tokens_on_failure!(sel) do
            send(_sel)
          end
        end
      end
      sel
    end

    def_p :default do
      p_range_or_time
    end

    def_p :range_or_time do
      p_range or
      p_time_expr or
      raise make_error Error::Syntax, "not range or time"
    end

    def_p :range do
      if p_between and a = p_time_expr and p_and and b = p_time_expr
        TimeRange.new(a, b)
      end
    end

    def_p :between do
      token.type == :range and
        token.value == :between and
        take_token.value
    end

    def_p :and do
      token.type == :logical and
        token.value == :and and
        take_token.value
    end

    def_p :time_expr do
      case
      when v = p_numeric_relative
        v
      when v = p_time
        v
      when v = p_time_or_date_relative
        v
      when (r = p_relation and v = p_time_expr)
        v += r
      else
        return nil
      end

      if op = p_operation and interval = p_interval
        case op
        when :+
          v += interval
        when :-
          v -= interval
        else
          raise make_error Error, "unexpected time interval operation #{op.inspect}"
        end
      end

      v
    end

    # 10 sec before now
    # 10 sec ago
    def_p :numeric_relative do
      if (interval = p_interval)
        case
        when (direction = p_relation and time = p_time_expr)
          time + (interval * direction)
        when (direction = p_relative)
          TimeWithUnit.new(now, interval) + (interval * direction)
        end
      end
    end

    # 10 secs|day
    def_p :interval do
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
    def_p :relation do
      token.type == :relation and take_token.value
    end

    # ago
    def_p :relative do
      token.type == :relative and take_token.value
    end

    # + interval
    def_p :operation do
      token.type == :operation and take_token.value
    end

    def_p :time do
      TimeWithUnit === token.value and take_token.value
    end

    def_p :time_or_date_relative do
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
      tr.merge!(t)
      t = TimeWithUnit.new(tr.to_time, unit)
      t
    end

    # 12pm|12:30a|12:34:56pm
    def_p :time_relative do
      token.type == :time_relative and
        TimeRelative === token.value and
        take_token.value
    end

    # 2001/01|2001-02-20
    def_p :date_relative do
      token.type == :date_relative and
        TimeRelative === token.value and
        take_token.value
    end

    def _wrap_p! sel, &blk
      if @debug
        $stderr.puts "  #{' ' * @p_depth} #{sel} ... | #{token.inspect} #{token.value.inspect}"
        @p_depth += 1
        begin
          restore_tokens_on_failure!(sel, &blk)
        ensure
          @p_depth -= 1
          $stderr.puts "  #{' ' * @p_depth} #{sel} => #{result.inspect} | #{token.inspect}"
        end
      else
        restore_tokens_on_failure!(sel, &blk)
      end
    end

    def restore_tokens_on_failure!(sel)
      restore = true
      (@taken_tokens_stack ||= [ ]) << @taken_tokens
      @taken_tokens = [ ]
      begin
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
        case unit = get_unit_for_now($1)
        when :now
          value = TimeWithUnit.new(now, nil)
        else
          value = TimeWithUnit.new(now, unit)
        end
      when /\A(yesterday)\b/i
        value = TimeWithUnit.new(now, :day) - 1
      when /\A(tomorrow)\b/i
        value = TimeWithUnit.new(now, :day) + 1
      when /\A((this)\s+(#{TimeUnit::UNIT_REGEXP}))\b/io
        value = TimeWithUnit.new(now, $3)
      when /\A((previous|last|next)\s+(#{TimeUnit::UNIT_REGEXP}))\b/io
        value = TimeWithUnit.new(now, $3) + TimeInterval.new($2, $3)
      when /\A(#{TimeUnit::UNIT_REGEXP})\b/io
        value = TimeInterval.new(1, $1)
        type = :unit
      when /\A(ago)\b/i
        value = $1.downcase.to_sym
        value = @@direction_alias[value]
        type = :relative
      when /\A(before|after|from|since)\b/i
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
        raise make_error Error::Syntax, "syntax error"
      end
      token = $&
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

    def make_error cls, msg
      desc = describe_current_parse_position
      err = cls.new("#{msg} at position #{@pos}: #{desc.inspect}")
      err.position = @pos
      err.description = desc
      err
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
      case @now
      when Proc
        @now = @now.call
      end
      @now ||= Time.now
    end

    def get_unit_for_now name
      name = name.to_sym
      @unit_for_now[name] || @unit_for_now[nil]
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

  end # class
end # module

require 'qreport/time_parser/time_unit'
require 'qreport/time_parser/time_interval'
require 'qreport/time_parser/time_with_unit'
require 'qreport/time_parser/time_relative'
require 'qreport/time_parser/time_range'


