require 'spec_helper'
require 'qreport/time_parser/time_interval'

describe Qreport::TimeParser do
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

    it "should handle * Numeric" do
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
end

