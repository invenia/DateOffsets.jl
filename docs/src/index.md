# DateOffsets.jl

```@meta
CurrentModule = DateOffsets
```

[![stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://doc.invenia.ca/invenia/DateOffsets.jl/master)
[![latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://doc.invenia.ca/invenia/DateOffsets.jl/master)
[![build status](https://gitlab.invenia.ca/invenia/DateOffsets.jl/badges/master/build.svg)](https://gitlab.invenia.ca/invenia/DateOffsets.jl/commits/master)
[![coverage](https://gitlab.invenia.ca/invenia/DateOffsets.jl/badges/master/coverage.svg)](https://gitlab.invenia.ca/invenia/DateOffsets.jl/commits/master)

[DateOffsets.jl](https://gitlab.invenia.ca/invenia/DateOffsets.jl) provides the types and
functions necessary to generate dates with specific temporal offsets for use in training
and forecasting. Date offsets are important for defining data features with
[DataFeatures.jl](https://gitlab.invenia.ca/invenia/DataFeatures.jl).

## Types

`DateOffset` is an abstract type with two subtypes: `Horizon`s and `SourceOffset`s.

```
abstract DateOffset
    immutable Horizon
    abstract SourceOffset
        ...
```

### Horizon Type

[Horizons](@ref) allow the user to define the relationship between the time at which a
forecast runs (`sim_now`) and the forecast targets. These targets will typically be
`HourEnding` values; see the [Intervals.jl documentation](https://invenia.github.io/Intervals.jl/latest/)
for more information.

The relationship between `sim_now` and the targets is one-to-many.

```jldoctest
julia> using DateOffsets, Intervals, TimeZones, Base.Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; step=Hour(1), span=Day(1))
Horizon(1 hour, 1 day, 1 day, 0 hours)

julia> collect(targets(horizon, sim_now))
24-element Array{HourEnding{TimeZones.ZonedDateTime},1}:
 (2016-08-12 HE01-05:00]
 (2016-08-12 HE02-05:00]
 (2016-08-12 HE03-05:00]
 (2016-08-12 HE04-05:00]
 (2016-08-12 HE05-05:00]
 (2016-08-12 HE06-05:00]
 (2016-08-12 HE07-05:00]
 (2016-08-12 HE08-05:00]
 (2016-08-12 HE09-05:00]
 (2016-08-12 HE10-05:00]
 ⋮
 (2016-08-12 HE16-05:00]
 (2016-08-12 HE17-05:00]
 (2016-08-12 HE18-05:00]
 (2016-08-12 HE19-05:00]
 (2016-08-12 HE20-05:00]
 (2016-08-12 HE21-05:00]
 (2016-08-12 HE22-05:00]
 (2016-08-12 HE23-05:00]
 (2016-08-12 HE24-05:00]
```

### SourceOffset Type

[Source Offsets](@ref) allow the user to define the relationship between a forecast
target (or `sim_now`) and the date interval associated with the input data used to
generate that forecast (also called the "observation interval").

The relationship between a target date and an observation interval is one-to-one (applying
a single offset to a single target interval will return a single observation interval).

```jldoctest
julia> using DateOffsets, Intervals, TimeZones, Base.Dates

julia> target = HE(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
HourEnding{TimeZones.ZonedDateTime}(2016-08-12T01:00:00-05:00, Inclusivity(false, true))

julia> static_offset = StaticOffset(Day(-1))
StaticOffset(-1 day)

julia> apply(static_offset, target)
HourEnding{TimeZones.ZonedDateTime}(2016-08-11T01:00:00-05:00, Inclusivity(false, true))
```

One or more `SourceOffset`s must be defined for each `DataFeature`, but the user will
probably not [`apply`](@ref) these offsets manually, as this is handled by `FeatureQuery`
(via a call to [`observations`](@ref)).
