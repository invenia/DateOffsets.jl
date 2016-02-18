# Horizons

**TODO:** Figure out how to deal with private repos for these services (then update badge URLs):

```
[![Build Status](https://travis-ci.org/invenia/Horizons.jl.svg?branch=master)](https://travis-ci.org/invenia/Horizons.jl)
[![Build status](https://ci.appveyor.com/api/projects/status/.........?svg=true)](https://ci.appveyor.com/project/spurll/Horizons-jl)
[![codecov.io](https://codecov.io/github/invenia/Horizons.jl/coverage.svg?branch=master)](https://codecov.io/github/invenia/Horizons.jl?branch=master)
```

`Horizons.jl` provides generators for forecast input and output offsets. Given a base `DateTime` (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) (or any other `TimeType`) and some rules a `Task` (like a Python generator) is created that produces `DateTimes`s accordingly.

## Overview

The way horizons are dealt with in the Matlab Autopredictor are problematic. If we want to generate forecasts for each hour of a given day in a region that observes DST, the forecast will need to be configured for 25 horizons, and then only 24 (or 23) of these horizons are used.

Horizon `Task`s are designed to address these issues, replacing the following components of the Matlab Autopredictor:

  * Forecast **horizons**. For a given due (batch) date, the Matlab Autopredictor would make predictions for a series of horizons, each of which were `timedelta`s (`Period`s). These horizons would eventually be added to the due (batch) dates to obtain the target date. Instead of returning `Period`s, `Horizons.jl` returns `DateTime`s (or `ZonedDateTime`s) directly.
  * Static and dynamic **offsets**. When defining the data source features to use as model input, the Matlab Autopredictor took a base date (either the due date or the target date of the forecast) and for both static (e.g., three hours) and dynamic (e.g., same hour of the week) offsets.

**TODO:** Ensure that we can have offets based on target date and offsets based on due date (and they're not likely to be confused with each other).

## Examples

**TODO:** Provide examples of horizons, static offsets, dynamic offsets, etc.
