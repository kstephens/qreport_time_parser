require 'spec_helper'
require 'qreport/report_runner/time_parse'

describe Qreport::ReportRunner::TimeParse do
  attr :p
  before(:all) do
    @p = Qreport::TimeParser.new
    p.now = ::Time.parse("2011-04-27T08:23:37.981304")
    Qreport::ReportRunner.time_parser = p
  end
  context "time_parse" do
    it "should leave nil alone." do
      subject.time_parse(nil).should == nil
    end
    it "should leave Time alone." do
      now = Time.now
      subject.time_parse(now).should == now
    end
    it "should parse :now" do
      subject.time_parse(:now).should == Qreport::ReportRunner.time_parser.now
    end
    it "should parse 'now'." do
      subject.time_parse("now").should == (::Time.parse("2011-04-27T08:23:37.981304") ... ::Time.parse("2011-04-27T08:23:38.981304")) # questionable?
    end
    it "should parse 'now' with unit_for_now[:now] = :now." do
      pending
      p.unit_for_now[:now] = :now
      subject.time_parse("now").should == ::Time.parse("2011-04-27T08:23:37.981304")
    end
    it "should parse 't' with unit_for_now[:t] = :now." do
      pending
      subject.time_parse("t - 10 sec").should == ::Time.parse("2011-04-27T08:23:37.981304")
    end
    it "should parse relative date." do
      subject.time_parse("yesterday").should == (::Time.parse("2011-04-26T00:00:00") ... ::Time.parse("2011-04-27T00:00:00"))
    end
    it "should parse relative time." do
      subject.time_parse("previous hour").should == (::Time.parse("2011-04-27T07:00:00") ... ::Time.parse("2011-04-27T08:00:00"))
    end
  end
end

