# DateOffsets.jl

```@meta
CurrentModule = DateOffsets

DocTestSetup = quote
    using DateOffsets, Intervals, TimeZones, Dates

    # This is a hack to have nice printing that doesn't include module names.
    # https://github.com/JuliaDocs/Documenter.jl/issues/944
    @eval Main begin
        using DateOffsets, Intervals, TimeZones, Dates
    end
end
```

[![latest](https://img.shields.io/badge/docs-latest-blue.svg)](https://invenia.pages.invenia.ca/DateOffsets.jl/)
[![build status](https://gitlab.invenia.ca/invenia/DateOffsets.jl/badges/master/build.svg)](https://gitlab.invenia.ca/invenia/DateOffsets.jl/commits/master)
[![coverage](https://gitlab.invenia.ca/invenia/DateOffsets.jl/badges/master/coverage.svg)](https://gitlab.invenia.ca/invenia/DateOffsets.jl/commits/master)

[DateOffsets.jl](https://gitlab.invenia.ca/invenia/DateOffsets.jl) provides types and
functions necessary to generate dates with specific temporal offsets for use in training
and forecasting. Date offsets are important for defining data features with
[DataFeatures.jl](https://gitlab.invenia.ca/invenia/DataFeatures.jl).

### Horizon Type

[Horizons](@ref) allow the user to define the forecast targets in relation to the time the forecast runs (`sim_now`).
These targets will typically be `HourEnding` values.
See the [Intervals.jl documentation](https://invenia.github.io/Intervals.jl/latest/)
for more information.

The relationship between `sim_now` and the targets is usually one-to-many, e.g.
for a single `sim_now` you will usually generate 24 target hours for the following day:

```jldoctest
julia> using DateOffsets, Intervals, TimeZones, Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; step=Hour(1), span=Day(1))
Horizon(step=Hour(1), span=Day(1))

julia> collect(targets(horizon, sim_now))
24-element Array{AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed},1}:
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 3, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 4, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 5, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 6, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 7, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 8, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 9, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 10, tz"America/Winnipeg"))
 ⋮
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 16, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 17, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 18, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 19, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 20, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 21, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 22, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 23, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 13, tz"America/Winnipeg"))
```

### DateOffset Type

[`DateOffset`](@ref)s allow the user to define the relationship between a forecast
target (or `sim_now`) and the "observation interval" they wish to use in their model.

The relationship between a target date and an observation interval is one-to-one (applying
a single offset to a single target interval will return a single observation interval).

Offsets are defined as callable objects that operate on a single [`OffsetOrigins`](@ref).
An `OffsetOrigins` contains timing information, namely `sim_now` (the time the simulation
is running) and `target`, a forecast target.
These are both stored as `AnchoredIntervals`, typically `HourEnding`.

For convenience, the fields in `OffsetOrigins` are accessible through special kinds of `DateOffsets`:
[`Target`](@ref) and [`SimNow`](@ref).

```jldoctest offsets
julia> using DateOffsets, Intervals, TimeZones, Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
2016-08-11T02:00:00-05:00

julia> target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))

julia> origins = DateOffsets.OffsetOrigins(target, sim_now);

julia> StaticOffset(Day(-1))
StaticOffset(Target(), -1 day)

julia> StaticOffset(Day(-1))(origins)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
```

One or more `DateOffset`s must be defined for each `DataFeature`, but the user will
probably not apply these offsets manually, as this is handled via a call to
[`observations`](@ref).

More information and examples can be found in [Date Offsets](@ref).

#### Functions as offsets

Offsets can also be defined as functions that operate on a single [`OffsetOrigins`](@ref).
It is recommended to create a named function rather than nesting more than 3 `DateOffsets`
together to avoid difficulty when reading logs.

```jldoctest offsets
julia> StaticOffset(FloorOffset(DynamicOffset(Target(); fallback=Day(-1), if_after=SimNow()), Hour), Hour(-1))
StaticOffset(FloorOffset(DynamicOffset(Target(), -1 day, SimNow(), DateOffsets.always), Hour), -1 hour)

julia> long_offset(o) = floor(dynamicoffset(o.target; fallback=Day(-1), if_after=o.sim_now), Hour) - Hour(1)
long_offset (generic function with 1 method)

julia> long_offset(origins)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, tz"America/Winnipeg"))
```
