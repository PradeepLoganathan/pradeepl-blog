---
title: "Representing DateTime formats in API specifications"
lastmod: 2018-06-07T15:55:13+10:00
date: 2018-06-07T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - "API design"
  - "datetime"
categories:
  - "api"
  - "design"
summary: Representing dates in an API is a common but often not well thought out functionality.We need to be very cognizant of representing dates, intervals, and periods in the API Payload. There are two generally accepted date formats for API's.
ShowToc: true
TocOpen: false
images:
  - paul-buffington-M07hwL1O8ZI-unsplash.jpg
cover:
    image: "paul-buffington-M07hwL1O8ZI-unsplash.jpg"
    alt: "Dates in API's"
    caption: "Dates in API's"
    relative: false # To use relative path for cover image, used in hugo Page-bundles
 
---


Representing dates in an API is a common but often not well thought out functionality. APIs may be consumed globally, requiring support for different time zones and localization. Representing dates correctly in API specifications is key for data integrity, interoperability, consistency, and future compatibility. It helps ensure seamless communication between systems and reduces the likelihood of errors or misinterpretations when dealing with date and time information. As an example, Microsoft's guidelines for representing dates in API's is [here](https://github.com/Microsoft/api-guidelines/blob/master/Guidelines.md#113-json-serialization-of-dates-and-times). We need to be very cognizant of representing dates, intervals, and periods in the API Payload. There are two generally accepted date formats for API's.The two date formats are

## ISO 8601 format

The [ISO 8601](https://www.iso.org/iso-8601-date-and-time-format.html) standard is an International Standard for the representation of dates and times. This format contains date, time, and the offset from UTC, as well as the T character that designates the start of the time, for example, 2007-04-05T12:30:22-02:00. The pattern for this date and time format is ```YYYY-MM-DDThh:mm:ss.sTZD```. It is recommended to use the ISO-8601 format for representing the date and time in your RESTful web APIs.

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

It offers an unambiguous way of making comparisons between two dates simpler. The date and time values are organized from the most to the least significant components: year, month (or week), day, hour, minute, second, and fraction of second. All values are numbers with leading zeros to ensure that the correct number of digits are used. Hours are given in 24-hour time. In strict ISO 8601 format, a T is required between the date and the time. The time zone designator is required for all dates that are not UTC.  

The time zone designator is required for all dates that are not UTC. The time zone designator is optional for dates that are UTC. The time zone designator can be either expressed using the ±hh:mm format or using the "Z" format (UTC - Coordinated Universal Time). Z stands for Zulu time. Zulu Time Zone is 0 hours ahead of Greenwich Mean Time So 12:00 PM in Z is 12:00 PM in GMT and 5:30 PM in India.

## UTC Epoch format

Epoch or Unix time is defined as the number of seconds since midnight (UTC) on 1st January 1970. The value of epoch is the amount of seconds since the timestamp, minus the amount of leap seconds since then. A 10-digit value indicates it is in seconds, while a 13-digit value is indicative of a millisecond value. An example of an epoch time format is 1524715312 which converts to the ISO 8601 format of 2018-04-26T04:01:52Z

This [Wikipedia entry](http://en.wikipedia.org/wiki/Unix_time#History) explains a little about the origins of Unix time and the chosen epoch. The definition of Unix time and the epoch date went through a couple of changes before stabilizing on what it is now. Early versions of Unix measured system time in 1/60 s intervals. This meant that a 32-bit unsigned integer could only represent a span of time less than 829 days. For this reason, the time represented by the number 0 (called the epoch) had to be set in the very recent past. As this was in the early 1970s, the epoch was set to 1971-1-1. Later, the system time was changed to increment every second, which increased the span of time that could be represented by a 32-bit unsigned integer to around 136 years. As it was no longer so important to squeeze every second out of the counter, the epoch was rounded down to the nearest decade, thus becoming 1970-1-1. One must assume that this was considered a bit neater than 1971-1-1.

For example, the UTC epoch format for May 25, 2023, at 14:30:00 UTC can be represented as:
Seconds: 1680425400
Milliseconds: 1680425400000
When using the UTC epoch format in a REST API, you would typically include the date and time value as a numeric parameter or within the request or response payload, depending on the specific API design.

Note that a 32-bit signed integer using 1970-1-1 as its epoch can represent dates up to 2038-1-19, on which date it will wrap around to 1901-12-13. Take a look [here](https://en.wikipedia.org/wiki/Year_2038_problem) to understand the Year 2038 problem. To mitigate the Year 2038 problem, systems and applications are encouraged to transition to 64-bit systems or adopt alternative date and time representations that can handle a broader range of dates. Unix time is not particularly readable and certainly does not make it easy for people to interact with the service - either for exploratory or debug purposes. There are a number of online converters to convert epoch time into human readable formats. The most popular is [this one](https://www.epochconverter.com/).

## OpenAPI specs

In [OpenAPI specifications]({{< ref "/blog/openapi-specification-swagger">}}) also known as Swagger, dates can be represented using the "format" property within the schema definition. OpenAPI supports several standard date formats, including the ISO 8601 format. Some of the most common ways to represent dates in OpenAPI are

1.ISO 8601 Format: To represent dates in the ISO 8601 format, you can use the "format" property with the value "date".

```yaml
type: string
format: date
```

2.Date-Time Format: If you need to represent both date and time together, you can use the "format" property with the value "date-time".

```yaml
type: string
format: date-time
```

3.Custom Formats: You can also define custom date formats using the "pattern" property of OpenAPI specification. we can specify a custom pattern for the date format, such as "DD-MM-YYYY" as below

```yaml
type: string
pattern: "^\\d{2}-\\d{2}-\\d{4}$"
```

By specifying the appropriate "format" or "pattern" property in the schema definition, you can indicate the expected format for date values in your API endpoints. This helps in documenting and enforcing the correct representation of dates in the API, providing clarity to developers and consumers of the API.

## Conclusion

ISO-8601 is a portable, readable datetime format designed with data interchange in mind. It's supported by most languages either natively or through a third-party library. The ISO 8601 standard has been developed for clear communication of date and time information across countries, applications, and platforms. It is a standard that is used by the World Wide Web Consortium (W3C) and is supported by the ISO and other organizations. It fits in well with designing API's that can be used globally across different time zones, consumed by different languages, and used by different platforms.
