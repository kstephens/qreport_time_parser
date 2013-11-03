require 'qreport/time_parser'
require 'qreport/time_parser/time_unit'

module Qreport
  class TimeParser
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

      def + x
        case x
        when Numeric
          new(@amount + x, @unit)
        when TimeInterval
          new(@amount + x.to_sec, :sec)
        else
          raise TypeError, x.class.to_s
        end
      end

      def - x
        case x
        when Numeric
          new(@amount - x, @unit)
        when TimeInterval
          new(@amount - x.to_sec, :sec)
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
          to_sec / x.to_sec
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

      def to_s
        "#{@amount.inspect} #{@unit.inspect}"
      end

      def inspect
        "#<#{self.class} #{to_s}>"
      end

    end
  end
end
