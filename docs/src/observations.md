# [Observation Intervals](@id observation-intervals)

An observation interval (or "observation date") is the span of time associated with a piece of data used to generate a forecast or train a model.
The [`observations`](@ref) function translates a set of [`DateOffset`](@ref)s into the desired observation intervals for the data to be fetched from the [`S3DB.jl`](https://invenia.pages.invenia.ca/S3DB.jl/).

For example, say it's `2016-08-11T09:00` and we want to predict the electrical load for tomorrow at noon. 
Our target is the interval between 11:00 and 12:00 on 2016-08-12, which we can abbreviate `(2016-08-12 HE12]`. 
We might want to look at the most recent available electrical load for the same hour of the day (a dynamic offset which would give us an observation of `(2016-08-10 HE12]`) and the most recent available weather forecast for the two hours leading up to the target date (static offsets of -2 and -1 hours, giving us observation intervals of `(2016-08-12 HE10]` and `(2016-08-12 HE11]`).

## Example

```@repl
using DateOffsets, TimeZones, Dates
sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
offsets = [FloorOffset(SimNow()), StaticOffset(Day(1))]
s, t, o = observations(offsets, Horizon(), sim_now);
s
t
o
```
