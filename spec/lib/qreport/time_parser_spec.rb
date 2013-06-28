require 'spec_helper'
require 'qreport/time_parser'

describe Qreport::TimeParser do
  describe 'examples' do
    examples = Qreport::TimeParser.examples
    now = examples[:now]
    examples.each do | expr, val |
      next if Symbol === expr
      it "should translate #{expr.inspect} to #{val.inspect}" do
        t = nil
        begin
          tp = Qreport::TimeParser.new
          tp.now = now
          # tp.debug = true if expr =~ /between/i
          t = tp.parse(expr)
        rescue Qreport::TimeParser::Error => exc
          t = exc
        end
        t.to_s.should == val
      end
    end
  end
end

