require 'qreport/time_parser'
require 'qreport/time_parser/time_unit'

module Qreport
  class TimeParser
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
  end
end
