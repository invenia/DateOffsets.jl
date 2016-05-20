# Horizons

`Horizons.jl` provides the tools necessary to generate dates with specific temporal
offsets for forecast and input data.

For example, if we are generating a set of forecasts on a date, the system needs to know
what the appropriate `target_date`s for those forecasts would be. Or given a forecast
`target_date`, you might want to know which input datapoints need to be fetched from the
database to produce that forecast.

## Overview and Terminology

### Horizons and Data Source Offsets

Our systems uses temporal offsets for two primary purposes: to define **horizons** and
**data source offsets**.

**Horizon:** Horizons define the target dates for a given set of forecasts. Horizon
offsets are determined by reference to the current date (`sim_now`).

**Data Source Offset:** Data source offsets define the target dates for input data (data
used to generate forecasts). Data source offsets are typically determined by reference to
the forecast target date (although they can use `sim_now` instead).

### Static and Dynamic Offsets

Temporal offsets are typically described as either **static** or **dynamic**.

**Static Offset:** Static offsets are offsets that are defined by simple numeric values.
These offsets can be applied to one date to arrive at another using basic arithmetic.

For our purposes, even offsets that do not on their own translate to a consistent known
number of seconds, such as "two months" (or even "one day", in the case of daylight saving
time) are still defined as "static". Julia (in conjunction with TimeZones.jl) provides
excellent date support, making this relatively simple.

**Dynamic Offset:** Dynamic offsets are offsets with more complex definitions. Typically
these offsets are defined by nonnumeric properties of a date, or based on numeric
properties of a date matching specific values; "the first hour after X that doesn't fall
on a holiday" and "the first hour before X that has the same hour of day as Y" are
dynamic offsets.

For example, let's say we have two dates, which we'll call `d1` and `d2`. If we want an
offset that will give us "the first hour after `d1` that has the same hour of day as
`d2`", this would be a dynamic offset. If, however, `d2` weren't involved and we simply
wanted "the next hour after `d1` that has the same hour of day as `d1`", this could be
defined as a static offset of one day (irrespective of DST, because TimeZones.jl handles
that just fine).

### `sim_now`

In a live system, horizons and some data source offsets are calculated with reference to
the current time. But when backruns are performed, they cannot use the actual current
time; instead, we need some way to inform `Horizons.jl` what the "current" time would be
if this were a live run, to ensure that backrun simulations perform identically to the
live system.

Additionally, when data fetching occurs a backrun's "current" time must be compared to the
`available_date` of the data to ensure that the system is not cheating (making use of data
that would not be available yet in a live run).

This is accomplised with `sim_now`, a variable which defaults to `now(TimeZone("UTC"))`).

Live runs can sometimes use the default value for `sim_now` (`now(TimeZone("UTC"))`) to
represent the current date, but in some cases the time zone will be relevant, and in those
cases a value for `sim_now` (zoned appropriately) should be passed in.

For example, for forecast horizons for the next four hours, you might call
`horizon_hourly(Dates.Hour(1):Dates.Hour(4))`. The resulting target dates would have a UTC
time zone, but would represent the appropriate instant.

However, calling `horizon_next_day()` without providing a `sim_now` results in target
dates for every hour of the next UTC day. So if you're forecasting for EST, and the
current time is 20:00 EST on Friday, it is currently 01:00 UTC on Saturday, and the target
dates passed back would be for 01:00 UTC Sunday through 00:00 UTC Monday (20:00 EST on
Saturday through 21:00 EST on Sunday), which is probably not what you want. In this case,
call `horizon_next_day(now(FixedTimeZone("-05:00")))`, and the result will be 01:00 EST
on Saturday through 00:00 EST on Sunday instead.

### Our Use Case

The most common use cases for data source offsets are:

1. For forecast input data (like NWP), in which case the forecast `target_date` is simply
   used as the input data's `target_date` (with no offset).
    * In this case there's no need to create fallback dates; for each forecast
      `target_date`, either that data point is available or not, so the data fetching code
      can simple use the target date appropriately (in conjunction with whatever `sim_now`
      happens to be).
    * This can also be supported by creating a `SourceOffset` with the appropriate
      `target_date` and `limit=1`, meaning that no fallback dates will be calculated.
2. For actuals data (like recent load or price) with some dynamic offset, the forecast
   `target_date` is used as the base date, and using the dynamic offset criteria (a
   `DateFunction`, which `SourceOffset`s and `Fallback`s call `match`) a `SourceOffset` is
   returned.
    * The `SourceOffset` contains a `Fallback` for each forecast `target_date`. The
      `Fallback` is an iterator that initially returns the `target_date`, then
      subsequently returns the next earlier date that meets the `match` criteria (using
      `toprev`), up to a maximum of `limit` iterations.
    * The forecast `target_dates` are **rounded down** (`floor`ed) to the appropriate
      `resolution` (that of the data source in question) before being used as the basis
      for anything.
    * The purpose of the `Fallback`s is to first provide a "best match" for data fetching;
      if that best match isn't "available" in the DB yet (based on checking its
      `available_date` against `sim_now`), the data fetching code can request the next
      fallback date to see if that's available instead.
3. For actuals data (like recent load or price) **without** a dynamic offset, `sim_now` can
   be passed into the `SourceOffset` constructor.
    * The resulting `SourceOffset` will contain only one `Fallback` (as only a single date
      was passed in). The dates returned by `Fallback` begin (near) the `sim_now` and
      iterate backward (using `toprev`? what's the `match` value?) up to a maximum of
      `limit` iterations.
    * Like the `target_date` in the previous use case, the `sim_now` is **rounded down**
      (`floor`ed) to the appropriate `resolution` (that of the data source in question)
      before being used as the basis for anything.
    * The purpose of the `Fallback`s is to first provide a "best match" for data fetching;
      if that best match isn't "available" in the DB yet (based on checking its
      `available_date` against `sim_now`), the data fetching code can request the next
      fallback date to see if that's available instead.

For all of these use cases, any desired static offsets can be performed outside of
`Horizons.jl` as desired, either before or after the dynamic offsets are calculated.  

None of these use cases require two sets of dates, so we don't ask for both the (scalar)
`sim_now` and the (iterable) `target_date`; whichever one is passed in is used as the
basis for the offset(s).






# -------------
# MEETING NOTES
# -------------

Don't implement static offsets (those can be done before/after in the data feeds code, or
the configuration, or whatever, but we don't need them here).

Dynamic offsets only need target dates as the input

Explain fallback dates

For each forecast target date passed in to the constructor, 

```
-------  SourceOffset type (or just a list?)
|     |
-------
|     |
-------
|     |
-------
|     |
-------
|     |
-------           -------  Fallback type
|     |   <-----  |     |
-------           -------
				  |     |
				  -------
				  |     |
				  -------
```

For all dynamic offsets, round the date input to the appropriate input data resolution
before doing any calculations. This usually won't matter when the input is a forecast
target date (although it might, if the forecast target dates are at higher resolution than
the input data), but it is crucial if the input is a `sim_now`.
(**TODO:** `round` or `floor`?)

Make sure you include examples for all three use cases
(include the fact that you'll have to duplicate the results of the "most recent data"
one based on number of target dates, because each forecast target wants the same point)


the SourceOffset type contains the `target_date` (or whatever) and an associated Fallback object
(it's not just a list of Fallbacks)


Configurable max # of fallbacks (`limit`)



**BRAINSTORM:** For `SourceOffset` constructors, accept both a "base date" and an "earliest date"?
More efficient, because you can pass in `sim_now` and get it started at an earlier data point?


## Horizons

Inputs
Returns

### Examples

#### Hourly Horizons

```julia
using TimeZones

sim_now = ZonedDateTime(DateTime(2016, 3, 12, 23, 15, 1), TimeZone("America/Winnipeg"))
target_dates = horizon_hourly(sim_now, Dates.Hour(1):Dates.Hour(8))

for t in target_dates
    println(t)
end
```

Output:

```
2016-03-13T01:00:00-06:00
2016-03-13T03:00:00-05:00
2016-03-13T04:00:00-05:00
2016-03-13T05:00:00-05:00
2016-03-13T06:00:00-05:00
2016-03-13T07:00:00-05:00
2016-03-13T08:00:00-05:00
2016-03-13T09:00:00-05:00
```

#### Next Day Horizons

```julia
sim_now = ZonedDateTime(DateTime(2016, 3, 12, 3, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_next_day(sim_now)

for t in target_dates
    println(t)
end
```

Output:

```
2016-03-13T01:00:00-06:00
2016-03-13T03:00:00-05:00
2016-03-13T04:00:00-05:00
2016-03-13T05:00:00-05:00
2016-03-13T06:00:00-05:00
2016-03-13T07:00:00-05:00
2016-03-13T08:00:00-05:00
2016-03-13T09:00:00-05:00
2016-03-13T10:00:00-05:00
2016-03-13T11:00:00-05:00
2016-03-13T12:00:00-05:00
2016-03-13T13:00:00-05:00
2016-03-13T14:00:00-05:00
2016-03-13T15:00:00-05:00
2016-03-13T16:00:00-05:00
2016-03-13T17:00:00-05:00
2016-03-13T18:00:00-05:00
2016-03-13T19:00:00-05:00
2016-03-13T20:00:00-05:00
2016-03-13T21:00:00-05:00
2016-03-13T22:00:00-05:00
2016-03-13T23:00:00-05:00
2016-03-14T00:00:00-05:00
```

The horizon functions (like `horizon_next_day`) have optional parameters (like how many
days ahead you want the target dates to begin) with reasonable defaults (in this case,
"start with the next day").

Another example, that does a single target date, two days ahead, at 15 minute resolution:

```julia
sim_now = ZonedDateTime(DateTime(2016, 11, 4, 12, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_next_day(sim_now, Dates.Minute(15), Dates.Day(2))
collect(target_dates)
```

Output:

```
100-element Array{Any,1}:
 2016-11-06T00:15:00-05:00
 2016-11-06T00:30:00-05:00
 2016-11-06T00:45:00-05:00
 2016-11-06T01:00:00-05:00
 2016-11-06T01:15:00-05:00
 2016-11-06T01:30:00-05:00
 2016-11-06T01:45:00-05:00
 2016-11-06T01:00:00-06:00
 2016-11-06T01:15:00-06:00
 2016-11-06T01:30:00-06:00
 2016-11-06T01:45:00-06:00
 2016-11-06T02:00:00-06:00
 ...
```

Note that in both examples, daylight saving time is handled properly.

## Data Source Offsets


We're not doing static offsets here: just do math



In order for offsets to be meaningful (and to prevent cheating) systems that fetch input
data from the database must, in addition to using the `target_date` supplied by the

***TODO***: example of the above

If the query fails because no data were available for the specified `target_date` that met
the `available_date` criteria, simply proceed to the next fallback `target_date` and
re-query.

***TODO***: example



### Examples

***TODO***


same hour of day

same hour of week

is a holiday

isn't a holiday






The way horizons are dealt with in the Matlab Autopredictor are problematic. If we want to
generate forecasts for each hour of a given day in a region that observes DST, the forecast
will need to be configured for 25 horizons, and then only 24 (or 23) of these horizons are
used.

In the old Matlab code we would see something like this:

```matlab
due_date = date('1 January 2016 03:00', 'America/Winnipeg')
horizons = timedelta(22:45, 'hours')    % Meant to be each hour of the next day.
target_dates = due_date + horizons      % 2 January 2016 01:00 through 3 January 2016 00:00.
```

This code has several problems, many involving DST transitions, where the value of the
horizons (and even the number of horizons!) will vary. For example:

```matlab
due_date = date('12 March 2016 03:00', 'America/Winnipeg')
horizons = timedelta(22:45, 'hours')    % Meant to be each hour of the next day.
target_dates = due_date + horizons      % 13 March 2016 01:00 through 14 March 2016 01:00.
```

We end up with an extra hour that we don't want or need due to the DST transition. To
correct the DST-related problems, we might do something like this in Julia:

```julia
using TimeZones

due_date = ZonedDateTime(DateTime(2016, 3, 12, 3, 0, 0), TimeZone("America/Winnipeg"))
horizon_start = Dates.trunc(due_date, Dates.Day) + Dates.Day(1) + Dates.Hour(1)
horizon_finish = Dates.trunc(a, Dates.Day) + Dates.Day(2)
target_dates = horizon_start:Dates.Hour(1):horizon_finish
```

While it's a credit to Julia (and the TimeZones.jl package) that its adjuster functions can
handle that, in practice it's a lot harder to interpret (and code correctly). This package
aims to simplify this process by providing easy-to-use horizon generator functions (tasks)
take a due date as input and produce target dates.

## More Than Just Horizons!

Horizon `Task`s are designed to address these issues, replacing the following components of
the Matlab Autopredictor:

  * Forecast **horizons**.
    * For a given due date, the Matlab Autopredictor would make predictions for a series
      of horizons, each of which were `timedelta`s (`Period`s). These horizons would
      eventually be added to the due dates to obtain the target date.
    * The Julia Autopredictor replaces "due dates" (batch dates) with `sim_now` (which
      defaults to `now(TimeZone("UTC"))`). Instead of returning `Period`s, `Horizons.jl`
      returns the target dates as `DateTime`s (or `ZonedDateTime`s) directly.
  * Source **offsets**.
    * When defining the data source features to use as model input, the Matlab
      Autopredictor took a vector of base dates (either due dates or forecast target
      dates) and used both static (e.g., three hours) and dynamic (e.g., same hour of the
      week) offsets to determine the appropriate target date to look for.
    * The Julia Autopredictor takes an interable of target dates and a `sim_now`. Most
      offsets will be calculated from the target date, but calculating from `sim_now`
      (for items like "most recent available actuals") will also be supported.

Among data source offsets, some offsets are based on target date (often used for forecast
data, such as NWP) and some are based on due date (often used for "most recent actuals"
data, such as recent actual generation). It's important to make the distinction between the
two non-ambiguous, as confusing one for the other will result in cheating.

## `sim_now`

The variable `sim_now` (which defaults everywhere to `now(TimeZone("UTC"))`) is used to
allow backrun simulations to accurate reflect the behaviour of a live system.

Live runs can typically use the default value for `sim_now` (`now(TimeZone("UTC"))`) to
represent the current date, but in some cases the time zone will be relevant, and in those
cases a value for `sim_now` (zoned appropriately) should be passed in.

For example, for forecast horizons for the next four hours, you might call
`horizon_hourly(Dates.Hour(1):Dates.Hour(4))`. The resulting target dates would have a UTC
time zone, but would represent the appropriate instant.

However, calling `horizon_next_day()` without providing a `sim_now` results in target
dates for every hour of the next UTC day. So if you're forecasting for EST, and the
current time is 20:00 EST on Friday, it is currently 01:00 UTC on Saturday, and the target
dates passed back would be for 01:00 UTC Sunday through 00:00 UTC Monday (20:00 EST on
Saturday through 21:00 EST on Sunday), which is probably not what you want. In this case,
call `horizon_next_day(now(FixedTimeZone("-05:00")))`, and the result will be 01:00 EST
on Saturday through 00:00 EST on Sunday instead.

## Examples

### Hourly Horizons

```julia
using TimeZones

sim_now = ZonedDateTime(DateTime(2016, 3, 12, 23, 15, 1), TimeZone("America/Winnipeg"))
target_dates = horizon_hourly(sim_now, Dates.Hour(1):Dates.Hour(8))

for t in target_dates
    println(t)
end
```

Output:

```
2016-03-13T01:00:00-06:00
2016-03-13T03:00:00-05:00
2016-03-13T04:00:00-05:00
2016-03-13T05:00:00-05:00
2016-03-13T06:00:00-05:00
2016-03-13T07:00:00-05:00
2016-03-13T08:00:00-05:00
2016-03-13T09:00:00-05:00
```

The `horizon` task/generator could mostly be replaced by simple `StepRange`s, now that Gem
got those working for `ZonedDateTime`s. The only feature that wouldn't be supported by a
generic `StepRange` is the `include`/`exclude` functions, which will probably only be used
for static/dynamic offsets (but they're available for horizons).

### Next Day Horizons

```julia
sim_now = ZonedDateTime(DateTime(2016, 3, 12, 3, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_next_day(sim_now)

for t in target_dates
    println(t)
end
```

Output:

```
2016-03-13T01:00:00-06:00
2016-03-13T03:00:00-05:00
2016-03-13T04:00:00-05:00
2016-03-13T05:00:00-05:00
2016-03-13T06:00:00-05:00
2016-03-13T07:00:00-05:00
2016-03-13T08:00:00-05:00
2016-03-13T09:00:00-05:00
2016-03-13T10:00:00-05:00
2016-03-13T11:00:00-05:00
2016-03-13T12:00:00-05:00
2016-03-13T13:00:00-05:00
2016-03-13T14:00:00-05:00
2016-03-13T15:00:00-05:00
2016-03-13T16:00:00-05:00
2016-03-13T17:00:00-05:00
2016-03-13T18:00:00-05:00
2016-03-13T19:00:00-05:00
2016-03-13T20:00:00-05:00
2016-03-13T21:00:00-05:00
2016-03-13T22:00:00-05:00
2016-03-13T23:00:00-05:00
2016-03-14T00:00:00-05:00
```

The horizon functions (like `horizon_next_day`) have optional parameters (like how many
days ahead you want the target dates to begin) with reasonable defaults (in this case,
"start with the next day").

Another example, that does a single target date, two days ahead, at 15 minute resolution:

```julia
sim_now = ZonedDateTime(DateTime(2016, 11, 4, 12, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_next_day(sim_now, Dates.Minute(15), Dates.Day(2))
collect(target_dates)
```

Output:

```
100-element Array{Any,1}:
 2016-11-06T00:15:00-05:00
 2016-11-06T00:30:00-05:00
 2016-11-06T00:45:00-05:00
 2016-11-06T01:00:00-05:00
 2016-11-06T01:15:00-05:00
 2016-11-06T01:30:00-05:00
 2016-11-06T01:45:00-05:00
 2016-11-06T01:00:00-06:00
 2016-11-06T01:15:00-06:00
 2016-11-06T01:30:00-06:00
 2016-11-06T01:45:00-06:00
 2016-11-06T02:00:00-06:00
 ...
```

Note that in both examples, daylight saving time is handled properly.

### Source Offsets


Target/Current Offsets?

Also pass back available dates for querying. All are the same. Necessary?

Example: Ignore holiday data. (Assuming there's a function that returns `true` for a holiday).

```julia
dates = source_offset(target_date; exclude=holiday)
```
