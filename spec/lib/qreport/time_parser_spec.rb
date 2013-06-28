require 'spec_helper'
require 'qreport/time_parser'

describe Qreport::TimeParser do
  describe Qreport::TimeParser::TimeRange do
    let(:a) { Qreport::TimeParser.new.parse("2013-01-23T12:34:56.901234Z") }
    let(:b) { a + 123456 }
    let(:r) { Qreport::TimeParser::TimeRange.new(a, b) }
    it "should return inspect" do
      r.inspect.should == "#<Qreport::TimeParser::TimeRange nil 2013-01-23T12:34:56.000000-06:00 ... nil 2013-01-24T22:52:32.000000-06:00>"
    end
  end

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

