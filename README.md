# Horizons

`Horizons.jl` provides generators for forecast input and output offsets. Given a base
`DateTime` (or any other `TimeType`) and some rules, a `Task` (like a Python generator) is
created that produces `DateTimes`s accordingly.

## Overview and Requirements

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
