require 'qreport/time_parser'

module Qreport
  class TimeParser
    module TimeUnit
      include Comparable
      attr_reader :unit

      def new *args
        self.class.new *args
      end

      def normalize!
        case @unit
        when nil
        when Symbol
          @unit = @@unit_alias[@unit] || @unit
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

      def self.pluralize str
        str = str.to_s
        case str
        when "day"
          "days"
        when /y\Z/
          str.sub(/y\Z/, 'ies')
        else
          str + "s"
        end
      end

      (@@unit_alias.to_a.flatten + @@unit_interval.keys).each do | x |
        next unless x
        next if x.size == 1
        x = x.to_sym
        @@unit_alias[pluralize(x).to_sym] ||= @@unit_alias[x] || x
      end

      def unit_multiplier unit = @unit
        @@unit_interval[unit] || 1
      end

      UNIT_REGEXP = 
        (@@unit_interval.keys + 
         @@unit_alias.keys + 
         @@unit_alias.values).
        uniq.
        map(&:to_s).
        reject(&:empty?).
        sort_by(&:size) * '|'
      # $stderr.puts "UNIT_REGEXP = #{UNIT_REGEXP}"

      def unit_interval
        @unit_interval ||=
          TimeInterval.new(1, @unit)
      end

      def <=> x
        case x
        when TimeInterval
          unit_interval <=> x.unit_interval
        else
          unit_interval <=> x
        end
      end

    end
  end
end
