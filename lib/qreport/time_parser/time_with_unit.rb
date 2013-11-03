require 'qreport/time_parser'
require 'qreport/time_parser/time_unit'

module Qreport
  class TimeParser
    class TimeWithUnit
      include TimeUnit
      include Comparable
      attr_reader :time

      def initialize time, unit
        @time, @unit = time, unit
        normalize!
      end

      def interval(amount, unit = nil)
        TimeInterval.new(amount, unit || @unit)
      end

      def + amount
        # debugger
        amount = interval(amount) if Numeric === amount
        raise TypeError, amount.to_s unless TimeInterval === amount
        new(@time + amount.to_sec, 
            [ unit_interval, amount.unit_interval ] )
      end

      def - x
        x = interval(x) if Numeric === x
        case x
        when TimeInterval
          new(@time - x.to_sec, unit_interval)
        when TimeWithUnit, ::Time
          interval(@time.to_f - x.to_f, unit_interval)
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
  end
end

