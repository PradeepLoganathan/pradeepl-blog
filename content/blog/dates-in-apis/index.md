---
title: "Dates in API's"
date: "2018-06-07"
categories: 
  - "api"
  - "architecture"
---

Representing dates in an API is a common but often not well thought out functionality. There are two generally accepted date formats for API's. Microsoft's guidelines for representing dates in API's is [here](https://github.com/Microsoft/api-guidelines/blob/master/Guidelines.md#113-json-serialization-of-dates-and-times) . We need to be very cognizant of representing dates, intervals, and periods in the API Payload. The two date formats are

### ISO 8601 format

The [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) standard is an International Standard for the representation of dates and times. This format contains date, time, and the offset from UTC, as well as the T character that designates the start of the time, for example, 2007-04-05T12:30:22-02:00. The pattern for this date and time format is YYYY-MM-DDThh:mm:ss.sTZD. It is recommended to use the ISO-8601 format for representing the date and time in your RESTful web APIs.

The formats for an ISO8601 date are as follows:

- Year: YYYY (2018)
- Year and month: YYYY-MM (2018-04)
- Complete date: YYYY-MM-DD (2018-04-25)
- Complete date plus hours and minutes: YYYY-MM-DDThh:mmTZD (2018-04-25T18:00+01:00)
- Complete date plus hours, minutes, and seconds: YYYY-MM-DDThh:mm:ssTZD (2018-04-25T18:00:30+01:00)
- Complete date plus hours, minutes, seconds, and a decimal fraction of a second: YYYY-MM-DDThh:mm:ss.sTZD (2018-04-25T18:00:30.45+01:00)

The letters used in the above format are:

- YYYY: Four-digit year
- MM: Two-digit month (01 = January, and so on)
- DD: Two-digit day of month (01 through 31)
- hh: Two digits of hour (00 through 23, a.m./p.m. NOT allowed)
- mm: Two digits of minute (00 through 59)
- ss: Two digits of second (00 through 59)
- s: One or more digits representing a decimal fraction of a second
- TZD: Time zone designator (Z or +hh:mm or -hh:mm)

It offers an unambiguous way of making comparisons between two dates simpler. The date and time values are organized from the most to the least significant components: year, month (or week), day, hour, minute, second, and fraction of second.

The time zone designator can be either expressed using the ±hh:mm format or using the "Z" format (UTC - Coordinated Universal Time). Z stands for Zulu time. Zulu Time Zone is 0 hours ahead of Greenwich Mean Time So 12:00 PM in Z is 12:00 PM in GMT and 5:30 PM in India.

### UTC Epoch format

Epoch or Unix time is defined as the number of seconds since midnight (UTC) on 1st January 1970. An example of an epoch time format is 1524715312 which converts to the ISO 8601 format of 2018-04-26T04:01:52Z

This [Wikipedia entry](http://en.wikipedia.org/wiki/Unix_time#History) explains a little about the origins of Unix time and the chosen epoch. The definition of Unix time and the epoch date went through a couple of changes before stabilizing on what it is now. Early versions of Unix measured system time in 1/60 s intervals. This meant that a 32-bit unsigned integer could only represent a span of time less than 829 days. For this reason, the time represented by the number 0 (called the epoch) had to be set in the very recent past. As this was in the early 1970s, the epoch was set to 1971-1-1. Later, the system time was changed to increment every second, which increased the span of time that could be represented by a 32-bit unsigned integer to around 136 years. As it was no longer so important to squeeze every second out of the counter, the epoch was rounded down to the nearest decade, thus becoming 1970-1-1. One must assume that this was considered a bit neater than 1971-1-1.

Note that a 32-bit signed integer using 1970-1-1 as its epoch can represent dates up to 2038-1-19, on which date it will wrap around to 1901-12-13. Take a look [here](https://en.wikipedia.org/wiki/Year_2038_problem) to understand the Year 2038 problem.

ISO-8601 is a portable, readable timestamp format designed with data interchange in mind. It's supported by most languages either natively or through a third-party library. Unix are not particularly readable and certainly don't make it easy for people to interact with the service - either for exploratory or debug purposes.

[Photo by](https://unsplash.com/search/photos/time?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) [Paul Buffington](https://unsplash.com/photos/M07hwL1O8ZI?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) [on](https://unsplash.com/search/photos/time?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) [Unsplash](https://unsplash.com/search/photos/time?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
