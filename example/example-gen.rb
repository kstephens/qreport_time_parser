#!/usr/bin/env ruby

require 'qreport/time_parser/examples'

fh = File.open("#{File.dirname(__FILE__)}/examples.rb", "w+")
def fh.p *args
  write "    "
  puts *args
end

fh.p "require 'qreport/time_parser'"
fh.p ""
examples = Qreport::TimeParser.examples
now = examples[:now]
fh.p "p = Qreport::TimeParser.new"
fh.p "p.now = Time.parse('#{now.iso8601}')"
fh.p ""
examples.each do | expr, val |
  next if Symbol === expr
  val, time_range = val if Array === val
  t = err = nil
  begin
    tp = Qreport::TimeParser.new
    tp.now = now
    # tp.debug = true if expr =~ /between/i
    t = tp.parse(expr)
  rescue Qreport::TimeParser::Error => exc
    $stderr.puts "ERROR: #{exc.inspect}"
    err = exc
  end
  fh.p "puts p.parse(#{expr.inspect}).to_TimeRange"
  if t
    fh.p "  # => #{t.to_TimeRange}"
    fh.p ""
  end
  if err
    fh.p "  # => #{err.inspect}"
    fh.p ""
  end
end

fh.close

