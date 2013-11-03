require 'qreport/time_parser'
require 'qreport/time_parser/time_unit'

module Qreport
  class TimeParser
    class TimeRange
      include Comparable
      attr_reader :a, :b

      def initialize a, b
        @a = a
        @b = b
      end

      def inspect
        "#<#{self.class} #{to_s}>"
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
  end
end
