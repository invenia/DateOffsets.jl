# Horizons

`Horizons.jl` provides generators for forecast input and output offsets. Given a base
`DateTime` (or any other `TimeType`) and some rules, a `Task` (like a Python generator) is
created that produces `DateTimes`s accordingly.

**TODO:** The tasks/generators for horizons could be replaced by simple `StepRange`s, now
that Gem got those working for `ZonedDateTime`s, but `StepRange`s are too simplistic to work
for the dynamic data offsets (offsets that can be defined like, "most recent data available
for the same hour of week as the target"). The plan is currently to use tasks for everything,
but this is still kind of up in the air right now. (Another possibility would be to separate
horizons and static/dynamic data offsets again, but as Gem and Curt discussed it seems like
a good idea to couple these two concepts.)

## Overview

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
due_date = ZonedDateTime(DateTime(2016, 1, 1, 3, 0, 0), TimeZone("America/Winnipeg"))
horizon_start = Dates.trunc(due_date, Dates.Day) + Dates.Day(1) + Dates.Hour(1)
horizon_finish = Dates.trunc(a, Dates.Day) + Dates.Day(2)
target_dates = horizon_start:Dates.Hour(1):horizon_finish
```

While it's a credit to Julia (and the TimeZones.jl package) that its adjuster functions can
handle that, in practice it's a lot harder to interpret (and code correctly). This package
aims to simplify this process by providing easy-to-use horizon generator functions (tasks)
take a due date as input and produce target dates. For example:

```julia
using TimeZones
due_date = ZonedDateTime(DateTime(2016, 1, 1, 3, 0, 0), TimeZone("America/Winnipeg"))
target_dates = horizon_next_day(due_date)
```

The horizon functions (like `horizon_next_day`) will have optional parameters (like how many
days ahead you want the target dates to begin) with reasonable defaults (in this case,
"start with the next day").

## More Than Just Horizons!

Horizon `Task`s are designed to address these issues, replacing the following components of
the Matlab Autopredictor:

  * Forecast **horizons**. For a given due (batch) date, the Matlab Autopredictor would make
    predictions for a series of horizons, each of which were `timedelta`s (`Period`s). These
	horizons would eventually be added to the due (batch) dates to obtain the target date.
	Instead of returning `Period`s, `Horizons.jl` returns `DateTime`s (or `ZonedDateTime`s)
	directly.
  * Static and dynamic **offsets**. When defining the data source features to use as model
    input, the Matlab Autopredictor took a base date (either the due date or the target date
	of the forecast) and for both static (e.g., three hours) and dynamic (e.g., same hour of
	the week) offsets.

**TODO:** Ensure that we can have offets based on target date (often used for forecast
data, such as NWP) and offsets based on due date (often used for "most recent actuals" data,
such as recent actual generation). It's important to make the distinction between the two
non-ambiguous, as confusing one for the other will result in cheating.

## Examples

**TODO:** Provide examples of horizons, static offsets, dynamic offsets, etc. beyond those
in the Overview section.
