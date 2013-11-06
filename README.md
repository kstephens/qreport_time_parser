# QreportTimeParser

A Time/Date parser with implicit precision.

## Installation

Add this line to your application's Gemfile:

    gem 'qreport_time_parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install qreport_time_parser

## Usage

Qreport::TimeParser will parse human-specified Time values into Time ranges with implicit precision.

## Examples

    require 'qreport/time_parser'
    
    p = Qreport::TimeParser.new
    p.now = Time.parse('2011-03-10T15:10:37-06:00')
    
    puts p.parse("now").to_TimeRange
      # => "nil 2011-03-10T15:10:37.981304-06:00 ... nil 2011-03-10T15:10:38.981304-06:00"
    
    puts p.parse("2011-03-10 15:10:37 -0600").to_TimeRange
      # => "nil 2011-03-10T15:10:37.000000-06:00 ... nil 2011-03-10T15:10:38.000000-06:00"
    
    puts p.parse("2011-03-10 15:10:37.981304 -0600").to_TimeRange
      # => "nil 2011-03-10T15:10:37.981304-06:00 ... nil 2011-03-10T15:10:38.981304-06:00"
    
    puts p.parse("today").to_TimeRange
      # => ":day 2011-03-10T00:00:00.000000-06:00 ... :day 2011-03-11T00:00:00.000000-06:00"
    
    puts p.parse("tomorrow").to_TimeRange
      # => ":day 2011-03-11T00:00:00.000000-06:00 ... :day 2011-03-12T00:00:00.000000-06:00"
    
    puts p.parse("yesterday").to_TimeRange
      # => ":day 2011-03-09T00:00:00.000000-06:00 ... :day 2011-03-10T00:00:00.000000-06:00"
    
    puts p.parse("9:15am yesterday").to_TimeRange
      # => ":min 2011-03-09T09:15:00.000000-06:00 ... :min 2011-03-09T09:16:00.000000-06:00"
    
    puts p.parse("yesterday 9:15am").to_TimeRange
      # => ":day 2011-03-09T00:00:00.000000-06:00 ... :day 2011-03-10T00:00:00.000000-06:00"
    
    puts p.parse("10 days ago").to_TimeRange
      # => ":day 2011-02-28T00:00:00.000000-06:00 ... :day 2011-03-01T00:00:00.000000-06:00"
    
    puts p.parse("10 s ago").to_TimeRange
      # => ":sec 2011-03-10T15:10:27.000000-06:00 ... :sec 2011-03-10T15:10:28.000000-06:00"
    
    puts p.parse("day before yesterday").to_TimeRange
      # => ":day 2011-03-08T00:00:00.000000-06:00 ... :day 2011-03-09T00:00:00.000000-06:00"
    
    puts p.parse("hr before tomorrow").to_TimeRange
      # => ":hour 2011-03-10T23:00:00.000000-06:00 ... :hour 2011-03-11T00:00:00.000000-06:00"
    
    puts p.parse("3 days before today").to_TimeRange
      # => ":day 2011-03-07T00:00:00.000000-06:00 ... :day 2011-03-08T00:00:00.000000-06:00"
    
    puts p.parse("5 days after today").to_TimeRange
      # => ":day 2011-03-15T00:00:00.000000-05:00 ... :day 2011-03-16T00:00:00.000000-05:00"
    
    puts p.parse("5 days before now").to_TimeRange
      # => "nil 2011-03-05T15:10:37.981304-06:00 ... nil 2011-03-05T15:10:38.981304-06:00"
    
    puts p.parse("3 days before this minute").to_TimeRange
      # => ":min 2011-03-07T15:10:00.000000-06:00 ... :min 2011-03-07T15:11:00.000000-06:00"
    
    puts p.parse("5 days before yesterday").to_TimeRange
      # => ":day 2011-03-04T00:00:00.000000-06:00 ... :day 2011-03-05T00:00:00.000000-06:00"
    
    puts p.parse("2 days before 50 hours after tomorrow").to_TimeRange
      # => ":hour 2011-03-11T02:00:00.000000-06:00 ... :hour 2011-03-11T03:00:00.000000-06:00"
    
    puts p.parse("2 centuries after today").to_TimeRange
      # => ":day 2211-01-21T00:00:00.000000-06:00 ... :day 2211-01-22T00:00:00.000000-06:00"
    
    puts p.parse("1pm").to_TimeRange
      # => ":hour 2011-03-10T13:00:00.000000-06:00 ... :hour 2011-03-10T14:00:00.000000-06:00"
    
    puts p.parse("12:30pm").to_TimeRange
      # => ":min 2011-03-10T12:30:00.000000-06:00 ... :min 2011-03-10T12:31:00.000000-06:00"
    
    puts p.parse("9:20am tomorrow").to_TimeRange
      # => ":min 2011-03-11T09:20:00.000000-06:00 ... :min 2011-03-11T09:21:00.000000-06:00"
    
    puts p.parse("6am 3 days from yesterday").to_TimeRange
      # => ":hour 2011-03-12T06:00:00.000000-06:00 ... :hour 2011-03-12T07:00:00.000000-06:00"
    
    puts p.parse("2001/01").to_TimeRange
      # => ":mon 2001-01-01T00:00:00.000000-06:00 ... :mon 2001-02-01T00:00:00.000000-06:00"
    
    puts p.parse("2001-01").to_TimeRange
      # => ":mon 2001-01-01T00:00:00.000000-06:00 ... :mon 2001-02-01T00:00:00.000000-06:00"
    
    puts p.parse("01/2001").to_TimeRange
      # => #<Qreport::TimeParser::Error::Syntax: syntax error at position 2: "01 |^| /2001">
    
    puts p.parse("2001/02/03 12:23pm").to_TimeRange
      # => ":min 2001-02-03T12:23:00.000000-06:00 ... :min 2001-02-03T12:24:00.000000-06:00"
    
    puts p.parse("12/31 12:59pm").to_TimeRange
      # => ":min 2011-12-31T12:59:00.000000-06:00 ... :min 2011-12-31T13:00:00.000000-06:00"
    
    puts p.parse("12/31 last year").to_TimeRange
      # => ":day 2010-12-31T00:00:00.000000-06:00 ... :day 2011-01-01T00:00:00.000000-06:00"
    
    puts p.parse("12:59:59pm 12/31 next year").to_TimeRange
      # => ":sec 2012-12-31T12:59:59.000000-06:00 ... :sec 2012-12-31T13:00:00.000000-06:00"
    
    puts p.parse("1:23:45pm 1/2 in 2 years").to_TimeRange
      # => ":sec 2013-01-01T13:23:45.000000-06:00 ... :sec 2013-01-01T13:23:46.000000-06:00"
    
    puts p.parse("2011-03-10T15:10:37-06:00").to_TimeRange
      # => "nil 2011-03-10T15:10:37.000000-06:00 ... nil 2011-03-10T15:10:38.000000-06:00"
    
    puts p.parse("2011-03-10T15:10:37.981304-06:00").to_TimeRange
      # => "nil 2011-03-10T15:10:37.981304-06:00 ... nil 2011-03-10T15:10:38.981304-06:00"
    
    puts p.parse("2011-03-10T15:10:37-06:00 plus 10 sec").to_TimeRange
      # => ":sec 2011-03-10T15:10:47.000000-06:00 ... :sec 2011-03-10T15:10:48.000000-06:00"
    
    puts p.parse("2011-03-10T15:10:37.981304-06:00 - 2 weeks").to_TimeRange
      # => "nil 2011-02-24T15:10:37.981304-06:00 ... nil 2011-02-24T15:10:38.981304-06:00"
    
    puts p.parse("now minus 2.5 weeks").to_TimeRange
      # => "nil 2011-03-10T15:10:35.481304-06:00 ... nil 2011-03-10T15:10:36.481304-06:00"
    
    puts p.parse("t - 10 sec").to_TimeRange
      # => "nil 2011-03-10T15:10:27.981304-06:00 ... nil 2011-03-10T15:10:28.981304-06:00"
    
    puts p.parse("123.45 sec ago").to_TimeRange
      # => "nil 2011-03-10T15:08:34.531303-06:00 ... nil 2011-03-10T15:08:35.531303-06:00"
    
    puts p.parse("year 2010").to_TimeRange
      # => ":year 2010-01-01T00:00:00.000000-06:00 ... :year 2011-01-01T00:00:00.000000-06:00"
    
    puts p.parse("between 12:45pm and 1:15pm").to_TimeRange
      # => ":min 2011-03-10T12:45:00.000000-06:00 ... :min 2011-03-10T13:15:00.000000-06:00"
    
    puts p.parse("before 1:23pm tomorrow").to_TimeRange
      # => ":min 2011-03-11T13:22:00.000000-06:00 ... :min 2011-03-11T13:23:00.000000-06:00"
    
    puts p.parse("this minute").to_TimeRange
      # => ":min 2011-03-10T15:10:00.000000-06:00 ... :min 2011-03-10T15:11:00.000000-06:00"
    
    puts p.parse("last hour").to_TimeRange
      # => ":hour 2011-03-10T14:00:00.000000-06:00 ... :hour 2011-03-10T15:00:00.000000-06:00"
    
    puts p.parse("previous hour").to_TimeRange
      # => ":hour 2011-03-10T14:00:00.000000-06:00 ... :hour 2011-03-10T15:00:00.000000-06:00"
    
    puts p.parse("last day").to_TimeRange
      # => ":day 2011-03-09T00:00:00.000000-06:00 ... :day 2011-03-10T00:00:00.000000-06:00"
    
    puts p.parse("previous day").to_TimeRange
      # => ":day 2011-03-09T00:00:00.000000-06:00 ... :day 2011-03-10T00:00:00.000000-06:00"
    
    puts p.parse("  2001-01 + 1234 ajsdkfsd hours").to_TimeRange
      # => #<Qreport::TimeParser::Error::Syntax: syntax error at position 17: "  2001-01 + 1234  |^| ajsdkfsd hours">


    # UNIMPLEMENTED YET:
    
    puts p.parse("15 sec").to_TimeRange
      # => #<Qreport::TimeParser::Error: Qreport::TimeParser::Error>
    
    puts p.parse("12 minutes").to_TimeRange
      # => #<Qreport::TimeParser::Error: Qreport::TimeParser::Error>
    

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
