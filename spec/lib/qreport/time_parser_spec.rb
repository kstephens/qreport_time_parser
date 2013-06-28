require 'spec_helper'
require 'qreport/time_parser'

describe Qreport::TimeParser do
  describe Qreport::TimeParser::TimeWithUnit do
    let(:a) { Qreport::TimeParser.new.parse("2013-01-23 12:34") }
    let(:b) { a + a.interval(123456, :sec) }
    let(:c) { a + a.interval(60) }
    it "should be a TimeWithUnit" do
      a.should be_a(Qreport::TimeParser::TimeWithUnit)
      b.should be_a(Qreport::TimeParser::TimeWithUnit)
    end
    it "should handle -" do
      (b - a).inspect.should == "#<Qreport::TimeParser::TimeInterval 123456.0 nil>"
    end
    it "should handle -" do
      (c - a).inspect.should == "#<Qreport::TimeParser::TimeInterval 3600.0 nil>"
    end
    it "should #inspect." do
      a.inspect.should == "#<Qreport::TimeParser::TimeWithUnit :min 2013-01-23T00:34:00.000000-06:00>"
    end
    it "should convert to Range of Time." do
      a.to_range.should == (a.to_time ... (a.to_time + 60))
    end
  end

  describe Qreport::TimeParser::TimeInterval do
    let(:a) { Qreport::TimeParser::TimeInterval.new(123, nil) }
    let(:b) { Qreport::TimeParser::TimeInterval.new(123, :sec) }
    let(:c) { Qreport::TimeParser::TimeInterval.new(123, :min) }
    let(:d) { Qreport::TimeParser::TimeInterval.new(123, :hr) }
    it "should handle +" do
      (a + a).inspect.should == "#<Qreport::TimeParser::TimeInterval 246 :sec>"
      (a + b).inspect.should == "#<Qreport::TimeParser::TimeInterval 246 :sec>"
      (a + c).inspect.should == "#<Qreport::TimeParser::TimeInterval 7503 :sec>"
      (a + d).inspect.should == "#<Qreport::TimeParser::TimeInterval 442923 :sec>"
    end
    it "should handle -" do
      (a - a).inspect.should == "#<Qreport::TimeParser::TimeInterval 0 :sec>"
      (a - b).inspect.should == "#<Qreport::TimeParser::TimeInterval 0 :sec>"
      (a - c).inspect.should == "#<Qreport::TimeParser::TimeInterval -7257 :sec>"
      (a - d).inspect.should == "#<Qreport::TimeParser::TimeInterval -442677 :sec>"
    end

    it "should handle *" do
      (a * 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 246 nil>"
      (b * 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 246 :sec>"
      (c * 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 246 :min>"
      (d * 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 246 :hour>"
    end

    it "should handle / Numeric" do
      (a / 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 61 nil>"
      (b / 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 61 :sec>"
      (c / 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 61 :min>"
      (d / 2).inspect.should == "#<Qreport::TimeParser::TimeInterval 61 :hour>"
    end

    it "should handle / TimeInterval" do
      (a / a).should == 1
      (b / a).should == 1
      (c / a).should == 60
      (d / a).should == 3600
    end
  end

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

