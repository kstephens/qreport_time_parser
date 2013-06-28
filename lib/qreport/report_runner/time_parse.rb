require 'qreport/time_parser'

module Qreport
  class ReportRunner
    def self.time_parser
      Thread.current['Qreport::ReportRunner.time_parser'] ||= Qreport::TimeParser.new
    end
    def self.time_parser= x
      Thread.current['Qreport::ReportRunner.time_parser'] = x
    end
    module TimeParse
      def time_parse value, time_parser = nil
        p = time_parser || Qreport::ReportRunner.time_parser.dup
        case value
        when nil, ::Time
        when :now
          value = p.now
        when String
          value = p.parse(value)
        end
        case
        when value.respond_to?(:to_range)
          value = value.to_range
        when value.respond_to?(:to_time)
          value = value.to_time
        end
        value
      end
      extend self
    end
    include TimeParse
  end
end
