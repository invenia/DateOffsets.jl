# Horizons.jl

`Horizons.jl` provides the tools necessary to generate dates with specific temporal
offsets for use in training and forecasting.

## Contents

* [Overview](#overview)
* [Horizon Functions](#horizon-functions)
* [Data Feature Offset Functions](#data-feature-offset-functions)
* [Observation Date Function](#observation-dates-function)
* [Table Type](#table-type)
* [Cookbook](#cookbook)

## Overview

This package is concerned with three primary use cases:

1. Generating the `target_date`s for a batch of forecasts
2. Determining the `target_date`s for the input data to be passed into the models
3. Determining the `target_date`s for the input data used to train the models

The functions used in each case are referred to as:

1. [Horizon functions](#horizon-functions)
2. [Data feature offset functions](#data-feature-offset-functions)
3. [Observation date function](#observation-dates-function)

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
horizon_hourly{P<:Period}(sim_now::ZonedDateTime, periods::AbstractArray{P}; ceil_to::Period=Hour(1))
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
horizon_daily(sim_now::ZonedDateTime=now(TimeZone("UTC")); resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1), floor_to::Period=Day(1))
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

To apply one or more static offsets to your `target_dates`, use the `static_offset`
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
static_offset(dates::AbstractArray{ZonedDateTime}, offsets::Period...)
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

Dynamic offsets are offsets with more complex definitions. Typically these offsets are
defined by nonnumeric properties of a date, or based on numeric properties of a date
matching specific values; "the first hour after X that doesn't fall on a holiday" and "the
first hour before X that has the same hour of day as Y" are dynamic offsets.

For example, let's say we have two dates, which we'll call `d1` and `d2`. If we want an
offset that will give us "the last hour before `d2` that has the same hour of day as
`d1`", this would be a dynamic offset. If, however, `d2` weren't involved and we simply
wanted "the last hour before `d1` that has the same hour of day as `d1`", this could be
defined as a static offset of one day (irrespective of DST, because TimeZones.jl handles
that just fine). Looking at our specific use case, 

Several dynamic offset functions are available. Each of these functions takes a collection
of `target_dates`, a corresponding vector of `sim_nows`, and a `table`:
* `recent_offset`, which returns the `target_dates` of the most recent available data in
  the table
* `dynamic_offset_hourofday`, which returns the `target_dates` of the most recent
  available data in the table that have the same hour of day (0–23) as the corresponding
  forecast `target_dates`
* `dynamic_offset_hourofweek`, which returns the `target_dates` of the most recent
  available data in the table that have the same hour of week (0–167) as the corresponding
  forecast `target_dates`
* `dynamic_offset`, a which returns the `target_dates` of the most recent available data
  in the table that match explicit characteristics provided by the user

**Note:** `hourofday` and `hourofweek` above are written without underscores, following
the pattern laid out by `Dates.dayofweek`.

The `sim_now` vector must have one element for each row in the `target_date` collection
provided (see [Observation Dates Function](#observation-dates-function) for more
information). Data availability will vary by table, and the `table` argument gives the
dynamic offset function access to the necessary information (see [Table Type](#table-type)
for more information).

Here, "most recent available" is defined as the latest input data `target_date` less than
or equal to the forecast `target_date` that is expected to have an `availability_date`
(based on table metadata) less than or equal to the appropriate `sim_now`. This means
that:
* the `target_date` returned will not be later than the corresponding input `target_date`
  (even in cases, as with forecast input data, where later target dates are available)
* the `target_date` returned is expected to be available (barring data outages) as of the
  corresponding `sim_now` provided

If the `target_dates` generated by dynamic feature offset functions are later modified by
static offsets, these guarantees may no longer hold.

#### Signature

The `recent_offset`, `dynamic_offset_hourofday`, and `dynamic_offset_hourofweek` functions
have identical signatures:

```julia
recent_offset(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table)
```

```julia
dynamic_offset_hourofday(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table)
```

```julia
dynamic_offset_hourofweek(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table)
```

The more general `dynamic_offset` function takes an additional `step` argument and an
optional `match` keyword argument:

```julia
dynamic_offset(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, step::Period, table::Table; match::Function=current -> true)
```

In addition to being available at the appropriate `sim_now`, the candidate `target_date`
must also meet the criteria specified by `match`, a `DateFunction` (which defaults to
`return true`). A `DateFunction` is an "inclusion" funtion used by adjusters that takes a
single `TimeType` and returns true when it matches certain criteria (see Julia's
[adjuster function](http://docs.julialang.org/en/latest/manual/dates/#adjuster-functions)
documentation for more information).

When a candidate `target_date` does not fit our requirements, the `step` value indicates
how far back we should look before testing another candidate. The value of `step` must be
negative (indicating we first test the original `target_date` passed in, then step
**backward** before testing another).

The `step` should also be divisible by the resolution of the data in question. So if the
table has data at fifteen minute resolution, acceptable values for `step` would include
`Minute(-15)`, `Minute(-30)`, and `Hour(-1)`, but you wouldn't want to use `Minute(-10)`.
(If you did, the algorithm might end up choosing a target date for which you don't have
any data.)

#### Example

Suppose that have already defined our `target_dates` and corresponding `sim_nows`, and
we have tables called `pjm_http` (which contains actual market data) and `pjm_load` (which
contains load forecasts).

```julia
julia> display(target_dates)
4-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-26T15:00:00-05:00
 2016-07-26T16:00:00-05:00
 2016-07-26T17:00:00-05:00
 2016-07-26T18:00:00-05:00

julia> display(sim_nows)
4-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-26T13:56:39.036-05:00
 2016-07-26T13:56:39.036-05:00
 2016-07-26T13:56:39.036-05:00
 2016-07-26T13:56:39.036-05:00

julia> input_target_http = dynamic_offset_hourofweek(target_dates, sim_nows, pjm_http)
4-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-19T15:00:00-05:00
 2016-07-19T16:00:00-05:00
 2016-07-19T17:00:00-05:00
 2016-07-19T18:00:00-05:00

julia> input_target_load = dynamic_offset_hourofweek(target_dates, sim_nows, pjm_load)
4-element Array{TimeZones.ZonedDateTime,1}:
 2016-07-26T15:00:00-05:00
 2016-07-26T16:00:00-05:00
 2016-07-26T17:00:00-05:00
 2016-07-26T18:00:00-05:00
```

Take note that the input targets returned by the first call to `dynamic_offset_hourofweek`
are exactly one week earlier than those returned by the second. That's because the system
determined that data for the requested `target_dates` wouldn't be available in the first
table (it contains actual measurements, and the `target_dates` are in the future); the
dates returned are the most recent dates available that match the appropriate hour of
week. The second table contains forecast data that would be available.

#### Advanced Usage

If we wanted to do something a little more complicated, like return the most recent
available data that match the same hour of week but also don't fall on a holiday, we can
accomplish this with a call to the general `dynamic_offset` function.

Suppose that we have a function `holiday` that takes a `ZonedDateTime` and returns `true`
if the date in question in a holiday. You might write the call like this:

```julia
dynamic_offset(target_dates, sim_nows, Dates.Day(-7), table; match=x -> !holiday(x))
```

This will effectively match any day that is not a holiday and that shares an hour of week
with the appropriate `target_date` (because it will start at the `target_date` provided
and step backward one week at a time, keeping the hour of week constant).

## Observation Dates Function

When the system requires input data to train a model, it needs to know about more than
just the current date and our target. If the model to be trained will expect (say) four
pieces of recent data to produce a single forecast, training that model will require a
series of historical values for those four points and for the forecast target. These sets
of historical values are called "observations".

An "observation" constitutes the forecast target and the set of inputs required to produce
it. This means that a set of "observation dates" denotes the dates required to fetch these
data, namely the forecast `target_date` and associated `sim_now` (which, in combination
with the [data feature offset functions](#data-feature-offset-functions), also gives us
the input data `target_dates`).

The `observation_dates` function takes the collection of forecast `target_dates` and
single `sim_now` value, along with information about how much training data is desired,
and returns a tuple of observation `target_dates` and associated `sim_now`s. The vector of
`sim_now`s will be expanded such that it is the same length as the observation dates.

Each observation will have an associated forecast `target_date` and `sim_now`. Input data
feature `target_date`s can be calculated for these historical observations using the
static and dynamic offset functions in the same way they are for "real" forecast
`target_date`s.

Here is the expected execution path for the data offset functions:
* begin with a scalar `sim_now`
* pass `sim_now` into a [horizon function](#horizon-functions) to generate a collection of
  forecast `target_dates`
* pass `sim_now` and `target_dates` into the [observation dates function](#observation-dates-function)
  to generate a tuple of observation dates and associated `sim_nows`
* pass the observation dates and associated `sim_nows` into the appropriate [static and dynamic offset functions](#data-feature-offset-functions)
  to generate data feature `target_dates`

### Signature

```julia
observation_dates{P<:Period}(target_dates::AbstractArray{ZonedDateTime}, sim_now::ZonedDateTime, frequency::Period, training_window::Interval{P}...)
```

The `frequency` indicates the spacing between sets of observations (the difference
the `sim_now` associated with each set of `target_date`s). It should be equal to the
frequency at which batches of forecasts are generated.

Any number of `training_window`s may be provided. Each `training_window` is an `Interval`
(stolen, with attribution, from [AxisArrays.jl](#http://mbauman.github.io/AxisArrays.jl/latest/))
of `Period`s, indicating an offset from `sim_now`. See the example below.

Instead of passing `training_window` as an `Interval`, you may provide a single
`training_offset` value, which is equivalent to `Day(0) .. training_offset`.

If only a single period value is provided for the `training_window` (or if the interval
provided begins at `0`) the original `sim_now` and `target_dates` values passed in will
be included in the tuple returned. Otherwise, they will not.

### Example

The following example will give us `observation` dates and associated `sim_nows` with
training data for the last three months and the same three months of the previous year:

```julia
julia> sim_now = now(TimeZone("America/Winnipeg"))
2016-07-26T13:56:39.036-05:00

julia> target_dates = horizon_daily(sim_now)
2016-07-27T01:00:00-05:00:1 hour:2016-07-28T00:00:00-05:00

julia> observations, sim_nows = observation_dates(target_dates, sim_now, Dates.Day(1), Dates.Month(0) .. Dates.Month(3), Dates.Month(12) .. Dates.Month(15))
(TimeZones.ZonedDateTime[2015-04-27T01:00:00-05:00,2015-04-27T02:00:00-05:00,2015-04-27T03:00:00-05:00,2015-04-27T04:00:00-05:00,2015-04-27T05:00:00-05:00,2015-04-27T06:00:00-05:00,2015-04-27T07:00:00-05:00,2015-04-27T08:00:00-05:00,2015-04-27T09:00:00-05:00,2015-04-27T10:00:00-05:00  …  2016-07-27T15:00:00-05:00,2016-07-27T16:00:00-05:00,2016-07-27T17:00:00-05:00,2016-07-27T18:00:00-05:00,2016-07-27T19:00:00-05:00,2016-07-27T20:00:00-05:00,2016-07-27T21:00:00-05:00,2016-07-27T22:00:00-05:00,2016-07-27T23:00:00-05:00,2016-07-28T00:00:00-05:00],TimeZones.ZonedDateTime[2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00,2015-04-26T13:56:39.036-05:00  …  2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00,2016-07-26T13:56:39.036-05:00])
```

### Unexpected Behaviour with DST Transitions

Please note that if a time zone transition (DST, for example) occurs between the `sim_now`
and the `target_dates`, `observation_dates` will assume that this relationship between the
`sim_now` and the `target_dates` is representative, and will use this offset for all of
the historical observation dates it returns.

Similarly, if a time zone transition occurs **during** the time period covered by the
`target_dates` (meaning that the number of `target_dates` is itself unusual), this will be
assumed to be typical, and you will see (for example) 23 or 25 `target_dates` for each
unique `sim_now` in the observation dates returned.

Since we are training our models "on demand", it is actually possible that this is the
behaviour that we want (it means that the current model is trained up as though it were
typical, even though it isn't). If we **don't** want this, the function could be
redesigned to take a [horizon function](#horizon-functions) instead of an array of
`target_dates`. This would allow it to call the function for each of the unique
`sim_now`s, giving perfect results. We could even pass back the "real" forecast
`target_dates` in the tuple returned, meaning that the user never needs to call the
horizons function themselves.

**Note:** this function also assumes that all markets are siloed and run idependently
(which is currently true of our design). If we had a situation in which **another**
market's DST transition could affect the time that **this** market runs (say, if all
markets had to run at the same time), then the `observation_dates` code would have to be
much more complex.

We can discuss these issues and determine how we would like to proceed.


## Table Type

The `Table` composite type allows us to cache and reason about metadata specific to a
database table that stores information about data features. This information is used to
determine which input data `target_date` would be available at a given `sim_now`, which
is vital for calculating [dynamic feature offsets](#dynamic-feature-offsets).

`Table` contains a field for the table `name`. It also contains two dictionaries: `meta`
is a cache of the table's metadata (to minimize external calls to the DB) and `latest` is
a cache of the latest `target_date` that we expect to be available at a given `sim_now`
(since we expect to deal with multiple `target_date`s that all share the same `sim_now`,
caching these values should speed up repeated calls).

The constructor takes only the name of the table, as a `Symbol` or an `AbstractString`:

```julia
pjm_shadow = Table(:pjm_shadow)
```

## Cookbook

Here's an example that puts all of these offsets together in one place:

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
