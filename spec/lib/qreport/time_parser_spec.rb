require 'spec_helper'
require 'qreport/time_parser'

describe Qreport::TimeParser do
  describe 'examples' do
    examples = Qreport::TimeParser.examples
    now = examples[:now]
    examples.each do | expr, val |
      next if Symbol === expr
      it "should translate #{expr.inspect} to #{val.inspect}" do
        val, time_range = val if Array === val
        t = nil
        begin
          tp = Qreport::TimeParser.new
          tp.now = now
          # tp.debug = true if expr =~ /between/i
          t = tp.parse(expr)
        rescue Qreport::TimeParser::Error => exc
          t = exc.inspect
        end
        t.to_s.should == val
        t.to_TimeRange.to_s.should == time_range.to_s if time_range
      end
    end
  end
end

