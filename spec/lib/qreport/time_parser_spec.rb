require 'spec_helper'
require 'qreport/time_parser'
require 'qreport/time_parser/examples'

describe Qreport::TimeParser do
  context "intervals" do
    let(:p) { Qreport::TimeParser.new(:p_interval) }
    it "should parse intervals." do
      p.parse("10 seconds").inspect.should == "#<Qreport::TimeParser::TimeInterval 10 :sec>"
      p.parse("10 centuries").inspect.should == "#<Qreport::TimeParser::TimeInterval 10 :century>"
      p.parse("hour").inspect.should == "#<Qreport::TimeParser::TimeInterval 1 :hour>"
      p.parse("2013-01-23T12:34:56.901234Z").inspect.should == "nil"
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

