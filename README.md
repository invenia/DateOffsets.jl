# Horizons.jl




Overview


Explain Horizons
List functions

Explain Observation Dates
List function

Explain Offsets
List functions

Explain what a Table is
List constructor and show how it's used

Cookbook example
(Add comments explaining what's held where.)




## Cookbook Example

```julia
julia> using TimeZones

julia> using Horizons

julia> sim_now = now(TimeZone("America/Winnipeg"))
2016-07-22T15:26:23.284-05:00

julia> target_dates = horizon_next_day(sim_now)
2016-07-23T01:00:00-05:00:1 hour:2016-07-24T00:00:00-05:00

julia> observations, sim_nows = observation_dates(target_dates, sim_now, Dates.Day(1), Dates.Day(10))
(TimeZones.ZonedDateTime[2016-07-13T01:00:00-05:00,2016-07-13T02:00:00-05:00,2016-07-13T03:00:00-05:00,2016-07-13T04:00:00-05:00,2016-07-13T05:00:00-05:00,2016-07-13T06:00:00-05:00,2016-07-13T07:00:00-05:00,2016-07-13T08:00:00-05:00,2016-07-13T09:00:00-05:00,2016-07-13T10:00:00-05:00  …  2016-07-23T15:00:00-05:00,2016-07-23T16:00:00-05:00,2016-07-23T17:00:00-05:00,2016-07-23T18:00:00-05:00,2016-07-23T19:00:00-05:00,2016-07-23T20:00:00-05:00,2016-07-23T21:00:00-05:00,2016-07-23T22:00:00-05:00,2016-07-23T23:00:00-05:00,2016-07-24T00:00:00-05:00],^[[ATimeZones.ZonedDateTime[2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00,2016-07-12T15:26:23.284-05:00  …  2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00,2016-07-22T15:26:23.284-05:00])

julia> pjm_http = Table(:pjm_http)
Horizons.Table(:pjm_http,Dict{TimeZones.ZonedDateTime,TimeZones.ZonedDateTime}())

julia> data_source_targets_1 = recent_offset(observations, sim_nows, pjm_http)
264-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-12T00:00:00-04:00
 2016-07-12T00:00:00-04:00
 2016-07-12T00:00:00-04:00
 2016-07-12T00:00:00-04:00
 2016-07-12T00:00:00-04:00
 ⋮                        
 2016-07-22T00:00:00-04:00
 2016-07-22T00:00:00-04:00
 2016-07-22T00:00:00-04:00
 2016-07-22T00:00:00-04:00
 2016-07-22T00:00:00-04:00

julia> data_source_targets_2 = static_offset(observations, Dates.Day(-1), Dates.Day(1))
264×2 Array{TimeZones.ZonedDateTime,2}:
 2016-07-12T01:00:00-05:00  2016-07-14T01:00:00-05:00
 2016-07-12T02:00:00-05:00  2016-07-14T02:00:00-05:00
 2016-07-12T03:00:00-05:00  2016-07-14T03:00:00-05:00
 2016-07-12T04:00:00-05:00  2016-07-14T04:00:00-05:00
 2016-07-12T05:00:00-05:00  2016-07-14T05:00:00-05:00
 ⋮                                                   
 2016-07-22T20:00:00-05:00  2016-07-24T20:00:00-05:00
 2016-07-22T21:00:00-05:00  2016-07-24T21:00:00-05:00
 2016-07-22T22:00:00-05:00  2016-07-24T22:00:00-05:00
 2016-07-22T23:00:00-05:00  2016-07-24T23:00:00-05:00
 2016-07-23T00:00:00-05:00  2016-07-25T00:00:00-05:00

julia> data_source_targets_2 = dynamic_offset_hourofweek(data_source_targets_2, sim_nows, pjm_http)
264×2 Array{TimeZones.ZonedDateTime,2}:
 2016-07-05T01:00:00-05:00  2016-07-07T01:00:00-05:00
 2016-07-05T02:00:00-05:00  2016-07-07T02:00:00-05:00
 2016-07-05T03:00:00-05:00  2016-07-07T03:00:00-05:00
 2016-07-05T04:00:00-05:00  2016-07-07T04:00:00-05:00
 2016-07-05T05:00:00-05:00  2016-07-07T05:00:00-05:00
 ⋮                                                   
 2016-07-15T20:00:00-05:00  2016-07-17T20:00:00-05:00
 2016-07-15T21:00:00-05:00  2016-07-17T21:00:00-05:00
 2016-07-15T22:00:00-05:00  2016-07-17T22:00:00-05:00
 2016-07-15T23:00:00-05:00  2016-07-17T23:00:00-05:00
 2016-07-16T00:00:00-05:00  2016-07-18T00:00:00-05:00
```

Once the code above has been run, `data_source_targets_1` has the target dates
representing the most recent data that should be available in the `pjm_http` table, while
`data_source_targets_2` has target dates with (1) a static offset of one day in the future
and one day in the past that (2) have been dynamically shifted into the past such that
they have the same target hour of week (as the statically shifted dates) but should still
be available as of the appropriate `sim_now`.

Note that the time zone for `data_source_targets_1` is `UTC-4` instead of `UTC-5`. That's
because its dates were generated using most recent data from PJM, which is `UTC-4` at this
time. Note that in Julia it's perfectly acceptable to compare and reason about
`ZonedDateTime`s that are in different time zones, so this isn't a problem.



### Much of the implementation specifics in this document is currently out of date. Stand by for updates.

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
offsets are determined by reference to the current date (`sim_now`). Horizons are handled
using the `horizon_hourly` and `horizon_next_day` functions described in the
[Horizons](#horizons) section below.

**Data Source Offset:** Data source offsets define the target dates for input data (data
used to generate forecasts). Data source offsets are typically determined by reference to
the forecast target date (although they can use `sim_now` instead).  Data source offsets
are handled using the `SourceOffsets` and `Fallback` types described in the [Data Source
Offsets](#data-source-offsets) section below.

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

1. For forecast input data (like NWP) the forecast `target_date` is simply used as the
   input data's `target_date` (with no offset).
    * In this case it isn't strictly necessary to use the `SourceOffsets` type to create
      `Fallback` dates; for each forecast `target_date`, either that data point is
      available or not, so the data fetching code can simple use the target date
      appropriately (in conjunction with whatever `sim_now` happens to be).
    * This can also be supported by creating `SourceOffsets` without specifying a value
      for `limit`; when no `limit` keyword argument is specified, the `Fallback` will only
      contain a single source date (and won't actually "fall back" to any alternatives).
2. For actuals data (like recent load or price) with some dynamic offset, the forecast
   `target_date` is used as the base date, and using information about the data
   resolution and the dynamic offset criteria a `SourceOffsets` iterator is created:
    * The `SourceOffsets` will have a `Fallback` for each forecast `target_date`. The
      `Fallback` is an iterator that initially returns the `target_date`, then
      subsequently returns the next earlier date that meets the `match` criteria (using
      `toprev`), up to a maximum of `limit` iterations.
    * The forecast `target_dates` are **rounded down** (`floor`ed) to the appropriate
      `resolution` (that of the data source in question) before being used as the basis
      for anything. This is necessary in case the resolution of the `target_date` doesn't
      line up properly with the resolution of the data requested.
    * The purpose of the `Fallback` iterator is to first provide a "best match" for data
      fetching; if that best match isn't "available" in the DB yet (based on checking its
      `available_date` against `sim_now`), the data fetching code can request the next
      fallback date to see if that's available instead.
    * The `match` argument for `SourceOffsets` is a `DateFunction` factory (a function
      that returns a `DateFunction`; for examples refer to `match_hourofday` and
      `match_hourofweek`). Each `Fallback` will have a `match` property that is generated
      by calling the `DateFactory` function on the appropriate `target_date`.
3. For actuals data (like recent load or price) **without** a dynamic offset, the forecast
   `target_date` is still used as the base date.
    * If the difference between the `target_date` and `sim_now` is great and/or the
      forecast resolution is small, it is likely that many dates will have to be attempted
      before we find one that is "available".
        * To address this inefficiency, you can pass in the optional `base` keyword
          to indicate where fallback iteration should begin (if it is not supplied, the
          `target_date` is used).

For all of these use cases, any desired static offsets can be performed outside of
`Horizons.jl` as desired, either before or after the dynamic offsets are calculated.  

**TODO:** We could remove rounding if we agree that `sim_now` isn't going to be passed in!
(Actually, can't necessarily; the resolution of the target dates might not line up with
the resolution of the data.)



**TODO:** Check the match against the first one, too, to make sure it's a match.


# -----------------
# old meeting notes
# -----------------


SourceOffsets iterator type
    (Returns tuple of target_date, fallback)
Fallback iterator type

Don't implement static offsets (those can be done before/after in the data feeds code, or
the configuration, or whatever, but we don't need them here).

Explain fallback dates

For each forecast target date passed in to the constructor...

```
-------  SourceOffsets type (can't be a list because it needs to store forecast targets too)
|     |
-------
|     |
-------
|     |
-------
|     |
-------
|     |
-------          -------  Fallback type
|     |  <-----  |     |
-------          -------
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

Dynamic offsets...
Provides dynamic (complex, non-arithmetic) offsets. These offsets are specified by passing
in `DateFunction` factories (like `match_hourofday` or `match_hourofweek`). A `DateFunction`
is a function that takes a single `TimeType` as input and returns `true` when the input
matches the important criteria. A `DateFunction` factory is a function that takes a single
`TimeType` and returns a `DateFunction` to match new dates against an aspect of the date
passed into the factory.

# TODO: Most of the above no longer applies.


# -----------------
# NEW MEETING NOTES
# -----------------


Look into data sources interface

**TODO:** Add in static offsets. (Support before and after, but after is most important.)

Looks like we always have access to the target date. Therefore, we don't need to "fall back"
at all!

Take in the sim now and the column/table name, call curt's function to figure out what your
latest available target date is


Input can basically be like the kwargs you're using for SourceOffsets right now


Might want to make use of `:symbols` for references to things like `:target_date`

Input requires vector of target dates; returns abstractarray MxN of target dates, where
M is length(target dates) and N is number of static offsets?


Can we accomplish this using just successive function calls? Maybe not, but we should build
it that way first and use those in the back end?
e.g.
```
target_dates (10x1)
sim_now

# Needs release offset and resolution, both from the DB.
julia> source_targets = dynamic_offsets(target_dates, data_identifier (table/column), match_hourofweek, match_hourofday)

source_targets (10x2)

julia> source_targets = static_offset(source_targets, Day(-1), Hour(-12), Hour(+2))

source_targets (10x6)
```


Curt's math: `target_date + release_offset + datafeed_runtime <= sim_now`

So this means that if my dynamic offset functions *don't* take `sim_now` as an input,
I can take the `target_date` vector (passed in), subtract the `release_offset + datafeed_runtime`,
and then do my `toprev(match_function, target_date)`, and I'll be guaranteed something that
is <= `sim_now` anyway. Right? WRONG!

Specifically call out that in the old system, `"target_date"` was a dynamic offset. It is now the default.
WRONG!


DO WE NEED A `recent_offset`, which will just roll back the target dates to the latest available date?


# -----------------


`DateFunction` factories (like `match_hourofday` or `match_hourofweek`): a `DateFunction`
is a function that takes a single `TimeType` as input and returns `true` when the input
matches the important criteria. A `DateFunction` factory is a function that takes a single
`TimeType` and returns a `DateFunction` to match new dates against an aspect of the date
passed into the factory.



## Horizons

Inputs
Returns

### Examples

#### Hourly Horizons

**TODO:** Make all examples into doctests.

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
target_dates = horizon_next_day(sim_now; resolution=Dates.Minute(15), days_covered=Dates.Day(2))
collect(target_dates)
```

Output:

```
196-element Array{TimeZones.ZonedDateTime,1}:
 2016-11-05T00:15:00-05:00
 2016-11-05T00:30:00-05:00
 2016-11-05T00:45:00-05:00
 2016-11-05T01:00:00-05:00
 2016-11-05T01:15:00-05:00
 ...
 2016-11-06T23:00:00-06:00
 2016-11-06T23:15:00-06:00
 2016-11-06T23:30:00-06:00
 2016-11-06T23:45:00-06:00
 2016-11-07T00:00:00-06:00
```

Note that in both examples, daylight saving time is handled properly.

## Data Source Offsets


The `SourceOffsets` type can't simply be replaced by a list of `Fallback`s, because in
addition to returning the `Fallback` for each forecast `target_date` it also returns the
forecast `target_date` itself as part of the tupel.
the SourceOffsets type contains the `target_date` (or whatever) and an associated Fallback object
(it's not just a list of Fallbacks)


### `SourceOffsets` Type




### `Fallback` Type


We're not doing static offsets here: just do math



In order for offsets to be meaningful (and to prevent cheating) systems that fetch input
data from the database must, in addition to using the `target_date` supplied by the
`SourceOffsets`'s `Fallback`, take the current value of `sim_now` into account, comparing
it to the `available_date` in the database. This check is very imoprtant, but falls
outside the scope of `Horizons.jl`.

***TODO***: example of the above

If the query fails because no data were available for the specified `target_date` that met
the `available_date` criteria, simply proceed to the next fallback `target_date` and
re-query.

***TODO***: example



### Examples

For the purposes of these examples, let's assume we have a simple data fetching function
that looks something like this:

```julia
function fetch_data(sim_now, source_offsets)
    for (target_date, fallback) in source_offsets
        for data_date in fallback
            # Fetch the data for data_date from the database.
            # Check its available_date against sim_now.
            # If it isn't available yet, proceed to the next data_date.
            # Otherwise, break.
        end
    end
end
```

Assume also that we have initialized `sim_now` and `target_dates` to appropriate values:

```julia
sim_now = ZonedDateTime(DateTime(2016, 11, 4, 12, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_hourly(sim_now, Dates.Hour(1):Dates.Hour(8))
```

If we want to fetch forecast data with no fallback when the data isn't available yet,
we might do something like this:

```
fetch_data(sim_now, SourceOffsets(target_dates))
```

If we want recent actuals data with a dynamic offset that matches the same hour of day as
the forecast target date, we might do something like this:

```julia
source_offsets = SourceOffsets(
    target_dates;
    resolution=Dates.Hour(1),
    match=match_hourofday,
    limit=sim_now - Dates.Day(2)
)

fetch_data(sim_now, source_offsets)
```

Note that in the example above, we specify that the data is hourly, and we're ignoring any
data that is more than two days old. Instead of matching on same hour of day, we could
elect to match on same hour of week with `match_hourofweek`, although in that case we
would probably also want to extend the limit on how old the data is allowed to be. (It
would similarly be trivial to construct a function that would match or fail to match on a
holiday.)

If we simply want the most recent actuals data that's available, without any dynamic
offsets at all, we can do this:

```julia
source_offsets = SourceOffsets(
    target_dates;
    resolution=Dates.Hour(1),
    limit=sim_now - Dates.Hour(2)
)
```

**TODO:** Examples with a different base!

**TODO:** Test with different base!
