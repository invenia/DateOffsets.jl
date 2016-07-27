# Horizons.jl












`Horizons.jl` provides the tools necessary to generate dates with specific temporal
offsets for use in training and forecasting.

## Overview

This package is concerned with three primary use cases:

1. Generating the `target_date`s for a batch of forecasts
2. Determining the `target_date`s for the input data to be passed into the models
3. Determining the `target_date`s for the input data used to train the models

The functions used in each case are referred to as:

1. [Horizon functions](#horizon-functions)
2. [Data feature offset functions
3. Observation date function

### Period Ending Standard

While some data represent instantaneous values, often data are aggregated over a period
of time. It is common practice to use a single `DateTime` (or preferably `ZonedDateTime`)
to represent this contiguous stretch.

Someone (or maybe a database) might say, "Here's the forecast for Thursday at 11:00." Does
this mean the forecast for the period `[11:00, 12:00)`? Or is it perhaps `(10:00, 11:00]`?
Unless you've specified a standard, it's ambiguous.

ISOs typically use the **hour ending** standard (the second possibility in the example
above), and our system follows suit.

Since we also deal with data at resolutions finer than one hour, we use the more general
period ending standard (a data point that has a resolution of 15 minutes and is stamped
`15:45` represents values for the period `(15:30, 15:45]`).

**Note:** The general period ending standard only applies to data at resolution finer than
one day. Data at resolutions of one day and courser (think `Date`s, rather than
`DateTime`s) will often ignore the period ending rule because following it would result in
confusion (aggregate data for the day of `2016-01-31` being stamped `2016-02-01T00:00:00`,
for example).

### Current Date: `sim_now`

In a live system, there are many cases in which it is necessary to know the current date
and time in order to calculate an offset. In many cases a call to `now()` might suffice.

But when simulating historical performance of the system in a backrun (or training a
model), the actual current time would not be useful. Instead, we need some way to inform
the system what the "current" time **would be** if this were a live forecast. This ensures
that backrun simulations perform identically (or near as possible) to the live system, and
that the data fetched to train a model accurately represents the data that is passed into
that model to generate a forecast.

In addition to being used to generate `target_date`s, when data fetching occurs the
"current" time must be compared to the `available_date` of the data in the database to
ensure that the system is not cheating (that is to say: making use of data that would not
be available in the database yet if this were live run).

This is accomplised with `sim_now`, a variable that represents the "current time" in a
live forecast and the simulated historical time during a backrun or when fetching training
data.

Where a default value for `sim_now` is provided, it defaults to `now(TimeZone("UTC"))`).
(We may decide to remove default values entirely.)

A time zone must always be provided for `sim_now`, and there are cases in which an
incorrect time zone will result in erroneous behaviour. For example, when calling
`horizon_daily` (a function that provides all `target_date`s for the next day at hourly
resolution), what exactly constitutes "the next day" is determined by reference to the
time zone. If your `sim_now` is set to UTC, this will result in `target_date`s for every
hour of the next UTC day. So if you're forecasting for EST, and the current time is 20:00
EST on Friday, it is currently 01:00 UTC on Saturday, and the target dates passed back
would be for 01:00 UTC Sunday through 00:00 UTC Monday (20:00 EST on Saturday through
21:00 EST on Sunday), which is probably not what you want. In this case, call
`horizon_daily` with a `sim_now` of `now(FixedTimeZone("-05:00")))`, and the result will
be 01:00 EST on Saturday through 00:00 EST on Sunday instead.

## Horizon Functions

When the system is instructed to generate a new set of forecasts, the system needs to
determine what the appropriate `target_date`s for those forecasts would be. Horizon
functions are used to determine the target dates for a given set of forecasts.

**Legacy System:** In the legacy Matlab system, the offset between the time a forecast was
due and the time it targeted was called the "horizon", and these offsets (timedeltas) were
used for indexing the forecasts. Because the new system has no concept of a forecast "due
date" we refer to the `target_date` and `sim_now` instead of `target_date` and `horizon`.

The new system uses horizon functions to generate the `target_date`s of the forecasts
based on the current date (`sim_now`).

### Hourly Horizons

To calculate the `target_date`s for a batch of forecasts defined by discrete set of
offsets from the current time, use the `horizon_hourly` function. The function takes
`sim_now`, rounds it **up** to the nearest hour, and produces `target_date`s by adding
the offsets to the result.

**Legacy System:** This function produces `target_date`s in a very similar fashion to the
old Hydro Wind and Load systems.

#### Signature

```julia
function horizon_hourly{P<:Period}(sim_now::ZonedDateTime, periods::AbstractArray{P}; ceil_to::Period=Hour(1))
```

#### Example

```julia
julia> sim_now = now(TimeZone("America/Winnipeg"))
2016-07-26T13:56:39.036-05:00

julia> target_dates = horizon_hourly(sim_now, Dates.Hour(1):Dates.Hour(8))
2016-07-26T15:00:00-05:00:1 hour:2016-07-26T22:00:00-05:00

julia> collect(target_dates)
8-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-26T15:00:00-05:00
 2016-07-26T16:00:00-05:00
 2016-07-26T17:00:00-05:00
 2016-07-26T18:00:00-05:00
 2016-07-26T19:00:00-05:00
 2016-07-26T20:00:00-05:00
 2016-07-26T21:00:00-05:00
 2016-07-26T22:00:00-05:00
```

**Reminder:** The `target_date`s are period ending.

#### Advanced Usage

Despite the name, the `horizon_hourly` function you can be used generate `target_date`s at
any arbitrary resolution: the resolution of the output is determined by the resolution of
the range of offsets passed in (if using a `StepRange`, simply specify a `step` of the
desired resolution).

**Note:** Even when a higher resolution for the output is specified, the `sim_now` will
still be rounded up to the nearest hour before the offsets are applied. This behaviour may
be modified by specifying a different value for the keyword argument `ceil_to`.

### Daily Horizons

To calculate the `target_date`s for a batch of forecasts for a specific day, use the
`horizon_daily` function. The function takes `sim_now`, rounds it to the **following
day**, and produces `target_date`s for each hour of that day.

Since `sim_now` must be a `ZonedDateTime`, Daylight Saving Time will be properly accounted
for: no `target_date`s will be produced for hours that don't exist in the time zone and
hours that are "duplicated" will appear twice (with each being zoned correctly).

**Legacy System:** This function produces avoids some of the pitfalls of the legacy Matlab
system, which required that horizons be specified by a simple range of offsets, for when
dealing with markets that observe Daylight Saving Time (or other similar transitions) days
may be of variable length. This is difficult to account for using a set of timedeltas.

#### Signature

```julia
function horizon_daily(sim_now::ZonedDateTime=now(TimeZone("UTC")); resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1), floor_to::Period=Day(1))
```

#### Example

```julia
julia> sim_now = now(TimeZone("America/Winnipeg"))
2016-07-26T13:56:39.036-05:00

julia> target_dates = horizon_daily(sim_now)
2016-07-27T01:00:00-05:00:1 hour:2016-07-28T00:00:00-05:00

julia> collect(target_dates)
24-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-27T01:00:00-05:00
 2016-07-27T02:00:00-05:00
 2016-07-27T03:00:00-05:00
 2016-07-27T04:00:00-05:00
 2016-07-27T05:00:00-05:00
 2016-07-27T06:00:00-05:00
 2016-07-27T07:00:00-05:00
 2016-07-27T08:00:00-05:00
 2016-07-27T09:00:00-05:00
 2016-07-27T10:00:00-05:00
 2016-07-27T11:00:00-05:00
 2016-07-27T12:00:00-05:00
 2016-07-27T13:00:00-05:00
 2016-07-27T14:00:00-05:00
 2016-07-27T15:00:00-05:00
 2016-07-27T16:00:00-05:00
 2016-07-27T17:00:00-05:00
 2016-07-27T18:00:00-05:00
 2016-07-27T19:00:00-05:00
 2016-07-27T20:00:00-05:00
 2016-07-27T21:00:00-05:00
 2016-07-27T22:00:00-05:00
 2016-07-27T23:00:00-05:00
 2016-07-28T00:00:00-05:00
```

**Reminder:** The `target_date`s are period ending.

#### Advanced Usage

Here's a secret: `sim_now` isn't actually rounded **up** to the nearest day; instead, it's
rounded **down** and then the value of the `days_ahead` keyword argument (which defaults
to `Day(1)`) is added to it. This means that if you would like to produce forecasts
starting two days from now, you can simply specify a different value for `days_ahead` (in
this case, `Day(2)`).

The following keyword arguments are available for use:
* `resolution` (default: `Hour(1)`): the temporal resolution of the `target_date`s
  returned
* `days_ahead` (default: `Day(1)`): defines the offset between `floor(sim_now, ...)` and
  the first `target_date` (`Day(1)` means start with the first hour of the following day)
* `days_covered` (default: `Day(1)`): defines the total length of time covered by the
  range
* `floor_to` (default: `Day(1)`): the second argument passed into the
  `floor(sim_now, ...)` call referenced in the description of `days_ahead` above

**Note:** While the values of `days_ahead` and `days_covered` don't **have** to represent
a number of days, if they aren't then you're probably sufficiently far off the beaten path
that you should probably consider writing a new function.

## Data Feature Offset Functions

When the system is instructed to fetch input data to produce a forecast or train a model,
data feature offset functions are used to determine which datapoints the model requires.

It is important to distinguish between the `target_date` of the forecast we want to
produce (the time we're "forecasting for") and the `target_date` of the input data (the
time that a datapoint was measured; or, if we're using other forecast data as an input,
the time that input was "forecast for"). The data feature offset functions apply
transformations to the forecast `target_date`s, returning the `target_date`s of the input
data that need to be fetched from the database.

Generally, data feature offsets fall into two categories:
* [static feature offsets](#static-feature-offsets), which represent a simple arithmetic
  transformation on a `target_date` (e.g., subtract two hours)
* [dynamic feature offsets](#dynamic-feature-offsets), which represent a more complex
  transformation that also takes `sim_now` into account (e.g., the most recent datapoint
  available that has the same hour of day as the `target_date`).

**Legacy System:** In the legacy Matlab system, the offsets between the `target_date` of
the forecast and the `target_date` of the input data used were called "data source
offsets"; in some cases, these offsets were calculated based on the "due date" instead of
the `target_date`. Additionally, static and dynamic offsets were specified together as
part of a single structure, with the dynamic offset (if any) applied first, followed by
any static offsets. Because data in the legacy system didn't have associated
`available_date`s, static offsets often had to be appllied to compensate for data that
wouldn't be available yet. (Instead of requesting the "most recent" data, the user might
request data for the "due date - 3 hours" if it was known that it took up to three hours
for the data to be processed and available to the system.) The new system should remove
this necessity.

In the new system, all data feature offsets are calculated based on the `target_date`,
though in many cases both `sim_now` and information about the DB table are also required
to ensure that the requested data are available at the time of the forecast.

### Static Feature Offsets

To apply one or more static offsets to your `target_date`s, use the `static_offset`
function. This function takes a collection of dates and any number of `Period` offsets.
If multiple offsets are specified, the set of input dates is duplicated columnwise for
each offset such that each offset can be applied to the original set of dates in its
entirety. (So two columns of `target_dates` with three static offsets would result in a
six-column output array.)

Keep in mind that static offsets do not necessarily translate to a consistent known number
of seconds: offsets such as "two months" (or even "one day", in the case of daylight saving
time) would still be called a "static" offset even though it may resolve differently when
applied to different `ZonedDateTime` values. Julia (in conjunction with TimeZones.jl)
provides excellent date support, making this relatively transparent.

**Legacy System:** In the legacy Matlab system, static offsets were always applied after
any dynamic offsets. In the new system, users have the liberty too apply these offsets in
whichever order suits their purposes.

#### Signature

```julia
function static_offset(dates::AbstractArray{ZonedDateTime}, offsets::Period...)
```

The `offsets` can also be passed in as a single `AbstractArray{P}` where `P <: Period`.

#### Example

```julia
julia> sim_now = now(TimeZone("America/Winnipeg"))
2016-07-26T13:56:39.036-05:00

julia> target_dates = horizon_hourly(sim_now, Dates.Hour(1):Dates.Hour(4))
2016-07-26T15:00:00-05:00:1 hour:2016-07-26T18:00:00-05:00

static_offset(target_dates, Dates.Day(-1), Dates.Hour(1))
4×2 Array{TimeZones.ZonedDateTime,2}:
 2016-07-25T15:00:00-05:00  2016-07-26T16:00:00-05:00
 2016-07-25T16:00:00-05:00  2016-07-26T17:00:00-05:00
 2016-07-25T17:00:00-05:00  2016-07-26T18:00:00-05:00
 2016-07-25T18:00:00-05:00  2016-07-26T19:00:00-05:00
```

### Dynamic Feature Offsets

Several dynamic offset functions are available. Each takes a collection of `target_date`s,
a corresponding vector of `sim_now`s, and a `table`.

The `sim_now` vector must have one element for each row in the `target_date` collection
(see [Observation Date Function](#observation-date-function) for more information).
Data availability will vary by table, and the `table` argument gives the dynamic offset
function access to the necessary information (see [Table Type](#table-type) for more
information).




For dynamic offsets, remind that we need a 1-to-1 relationship between sim_now and target_date
(use output from the observation date function)



## Observation Date Function


Takes a target date, the training window(s), and the sim_now, then returns all target dates/sim_nows

3. When training a model, the system needs to fetch historical data (both inputs and
   targets) to use to train the models. The relationship between the `target_date` (and
   `sim_now`) for the forecast and the dates for the input data should be analoguous
   between the training dataset and the data used for prediction.
    * In the Matlab system, the `target_dates` of the historical data used for training
      were called "observations".
    * In the new system, the additional set of dates required for the training set are
      called "observation dates".



## Table Type

TODO: Explain what a Table is
List constructor and show how it's used



### Static and Dynamic Offsets

Temporal offsets are typically described as either **static** or **dynamic**.

**Static Offset:** Static offsets are offsets that are defined by simple numeric values.
These offsets can be applied to one date to arrive at another using basic arithmetic.


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
sim_now = ZonedDateTime(2016, 3, 12, 3, TimeZone("America/Winnipeg"))
target_dates = horizon_daily(sim_now)

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

The horizon functions (like `horizon_daily`) have optional parameters (like how many
days ahead you want the target dates to begin) with reasonable defaults (in this case,
"start with the next day").

Another example, that does a single target date, two days ahead, at 15 minute resolution:

```julia
sim_now = ZonedDateTime(DateTime(2016, 11, 4, 12, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_daily(sim_now; resolution=Dates.Minute(15), days_covered=Dates.Day(2))
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


## Cookbook Example

Putting it all together...

```julia
julia> using TimeZones

julia> using Horizons

julia> sim_now = now(TimeZone("America/Winnipeg"))
2016-07-22T15:26:23.284-05:00

julia> target_dates = horizon_daily(sim_now)
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

