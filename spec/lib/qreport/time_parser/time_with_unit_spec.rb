require 'spec_helper'
require 'qreport/time_parser/time_with_unit'

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
end
