---
title: "Multiversion Concurrency Control"
date: "2014-07-20"
---

Every developer I know of has used or uses databases on a daily basis, be it SQL Server or  Oracle but quite a few of them are stumped when asked how this SQL will execute and what would its output be.

insert into Employee select \* from Employee; Select \* from Employee;

Additionally what happens if multiple people execute this statement concurrently. Will the select lock the insert ? Will the insert lock the select ? How does the system maintain data integrity in this case ? The answers have ranged from, this is not a valid SQL statement to this will be an indefinite loop.

Some have also got it accurately but without an understanding of what happens in the background to be able to provide a consistent and accurate response to the above query. The situation is further complicated by the fact that the implementation which solves the above conundrum is referred to differently in the various database and transactional systems.

A simple way of solving the above problem is by using locks or latching. Using locks ensures data integrity but it also serializes all reads and writes. This approach is definitely not scalable since the lock will only allow a single transaction either read or write to happen. Locking has further evolved with ready only locks and other variations but is still inherently a concurrency nightmare. A better approach to effectively ensure data integrity and also ensure scalability is by using   Multiversion concurrency control pattern.

Multiversion Concurrency involves tagging an object with read and write timestamps. This way an access history is maintained for a data object. This timestamp information is maintained via change set numbers which are generally stored together with modified data in rollback segments. This enables multiple “point in time” consistent views based on the change set numbers stored.MVCC enables read-consistent queries and non-blocking reads by providing this “point in time” consistent views without the need to lock the whole table. In Oracle this change set number are called System change numbers commonly referred to as SCN’s.This is one of the most important scalability features for a database since this provides for maximum concurrency while maintaining read consistency.
