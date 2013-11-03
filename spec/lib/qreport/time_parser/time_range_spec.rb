require 'spec_helper'
require 'qreport/time_parser/time_range'

describe Qreport::TimeParser do
  describe Qreport::TimeParser::TimeRange do
    let(:a) { Qreport::TimeParser.new.parse("2013-01-23T12:34:56.901234Z") }
    let(:b) { a + 123456 }
    let(:r) { Qreport::TimeParser::TimeRange.new(a, b) }
    it "should return inspect" do
      r.inspect.should == "#<Qreport::TimeParser::TimeRange nil 2013-01-23T12:34:56.000000-06:00 ... nil 2013-01-24T22:52:32.000000-06:00>"
    end
  end
end

