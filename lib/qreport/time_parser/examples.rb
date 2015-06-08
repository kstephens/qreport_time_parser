require 'qreport/time_parser'

module Qreport
  class TimeParser
    def self.examples
      now = ::Time.parse("2011-03-10T15:10:37.981304-06:00")
      examples = {
        "now" => "nil 2011-03-10T15:10:37.981304-06:00",
        now.to_s => "nil 2011-03-10T15:10:37.000000-06:00",
        "2011-03-10 15:10:37.981304 -0600" => "nil 2011-03-10T15:10:37.981304-06:00",
        "today" => ":day 2011-03-10T00:00:00.000000-06:00",
        "tomorrow" => ":day 2011-03-11T00:00:00.000000-06:00",
        "yesterday" => ":day 2011-03-09T00:00:00.000000-06:00",
        "9:15am yesterday" => ":min 2011-03-09T09:15:00.000000-06:00",
        "yesterday 9:15am" => ":day 2011-03-09T00:00:00.000000-06:00", # FIXME
        "10 days ago" => ":day 2011-02-28T00:00:00.000000-06:00",
        "10 s ago" => ":sec 2011-03-10T15:10:27.000000-06:00",
        "day before yesterday" => ":day 2011-03-08T00:00:00.000000-06:00",
        "hr before tomorrow" => ":hour 2011-03-10T23:00:00.000000-06:00",
        "3 days before today" => ":day 2011-03-07T00:00:00.000000-06:00",
        "5 days after today" => ":day 2011-03-15T00:00:00.000000-05:00",
        "5 days before now" => "nil 2011-03-05T15:10:37.981304-06:00",
        "3 days before this minute" => ":min 2011-03-07T15:10:00.000000-06:00",
        "5 days before yesterday" => ":day 2011-03-04T00:00:00.000000-06:00",
        "2 days before 50 hours after tomorrow" => ":hour 2011-03-11T02:00:00.000000-06:00",
        "2 centuries after today" => ":day 2211-01-21T00:00:00.000000-06:00",
        "1pm" => ":hour 2011-03-10T13:00:00.000000-06:00",
        "12am" => ":hour 2011-03-10T00:00:00.000000-06:00",
        "12pm" => ":hour 2011-03-10T12:00:00.000000-06:00",
        "12:30pm" => ":min 2011-03-10T12:30:00.000000-06:00",
        "12:30a"  => ":min 2011-03-10T00:30:00.000000-06:00",
        "12:30p"  => ":min 2011-03-10T12:30:00.000000-06:00",
        "12:34:56a"  => ":sec 2011-03-10T00:34:56.000000-06:00",
        "9:20am tomorrow" => ":min 2011-03-11T09:20:00.000000-06:00",
        "6am 3 days from yesterday" => ":hour 2011-03-12T06:00:00.000000-06:00",
        "2001/01" => ":mon 2001-01-01T00:00:00.000000-06:00",
        "2001-02" => ":mon 2001-02-01T00:00:00.000000-06:00",
        "03/2001" => ":mon 2001-03-01T00:00:00.000000-06:00",
        "2001/02/03 12:23pm" => ":min 2001-02-03T12:23:00.000000-06:00",
        "12/31 12:59pm" => ":min 2011-12-31T12:59:00.000000-06:00",
        "12/31 last year" => ":day 2010-12-31T00:00:00.000000-06:00",
        "12:59:59pm 12/31 next year" => ":sec 2012-12-31T12:59:59.000000-06:00",
        "1:23:45pm 1/2 in 2 years" => ":sec 2013-01-01T13:23:45.000000-06:00",
        "2011-03-10T15:10:37-06:00" => "nil 2011-03-10T15:10:37.000000-06:00",
        "2011-03-10T15:10:37.981304-06:00" => "nil 2011-03-10T15:10:37.981304-06:00",
        "2011-03-10T15:10:37-06:00 plus 10 sec" => ":sec 2011-03-10T15:10:47.000000-06:00",
        "2011-03-10T15:10:37.981304-06:00 - 2 weeks" => "nil 2011-02-24T15:10:37.981304-06:00",
        "now minus 2.5 weeks" => "nil 2011-03-10T15:10:35.481304-06:00",
        "t - 10 sec" => "nil 2011-03-10T15:10:27.981304-06:00",
        "123.45 sec ago" => "nil 2011-03-10T15:08:34.531303-06:00",
        "year 2010" => ":year 2010-01-01T00:00:00.000000-06:00",
        "between 12:45pm and 1:15pm" => ":min 2011-03-10T12:45:00.000000-06:00 ... :min 2011-03-10T13:15:00.000000-06:00",
        "before 1:23pm tomorrow" => ":min 2011-03-11T13:22:00.000000-06:00",
        "this minute"   => [ ":min 2011-03-10T15:10:00.000000-06:00",
          ":min 2011-03-10T15:10:00.000000-06:00 ... :min 2011-03-10T15:11:00.000000-06:00"],
        "last hour"     => [ ":hour 2011-03-10T14:00:00.000000-06:00",
          ":hour 2011-03-10T14:00:00.000000-06:00 ... :hour 2011-03-10T15:00:00.000000-06:00" ],
        "previous hour" => [ ":hour 2011-03-10T14:00:00.000000-06:00",
          ":hour 2011-03-10T14:00:00.000000-06:00 ... :hour 2011-03-10T15:00:00.000000-06:00"],
        "last day"   => [ ":day 2011-03-09T00:00:00.000000-06:00",
          ":day 2011-03-09T00:00:00.000000-06:00 ... :day 2011-03-10T00:00:00.000000-06:00" ],
        "previous day" => ":day 2011-03-09T00:00:00.000000-06:00",
        "  2001-01 + 1234 ajsdkfsd hours" => "#<Qreport::TimeParser::Error::Syntax: syntax error at position 17: \"  2001-01 + 1234  |^| ajsdkfsd hours\">",
        "15 sec" => "#<Qreport::TimeParser::Error::Syntax: not range or time at position 6: \"15 sec |^| \">",
        "12 minutes" => "#<Qreport::TimeParser::Error::Syntax: not range or time at position 10: \"12 minutes |^| \">",
        "15 sec from now"     => ":sec 2011-03-10T15:10:52.000000-06:00", # FIXME
        "12 minutes from now" => "nil 2011-03-10T15:22:37.981304-06:00",
      }
      examples[:now] = now
      examples
    end
  end
end

