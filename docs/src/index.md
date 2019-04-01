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
julia> using DateOffsets, Intervals, TimeZones, Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; step=Hour(1), span=Day(1))
Horizon(step=Hour(1), span=Day(1))

julia> collect(targets(horizon, sim_now))
24-element Array{AnchoredInterval{-1 hour,ZonedDateTime},1}:
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 2, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 3, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 4, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 5, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 6, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 7, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 8, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 9, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 10, tz"America/Winnipeg"), Inclusivity(false, true))
 ⋮
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 16, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 17, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 18, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 19, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 20, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 21, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 22, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 23, tz"America/Winnipeg"), Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 13, tz"America/Winnipeg"), Inclusivity(false, true))
```

### SourceOffset Type

[Source Offsets](@ref) allow the user to define the relationship between a forecast
target (or `sim_now`) and the date interval associated with the input data used to
generate that forecast (also called the "observation interval").

The relationship between a target date and an observation interval is one-to-one (applying
a single offset to a single target interval will return a single observation interval).

```jldoctest
julia> using DateOffsets, Intervals, TimeZones, Dates

julia> target = HE(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"), Inclusivity(false, true))

julia> static_offset = StaticOffset(Day(-1))
StaticOffset(Day(-1))

julia> apply(static_offset, target)
AnchoredInterval{-1 hour,ZonedDateTime}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"), Inclusivity(false, true))
```

One or more `SourceOffset`s must be defined for each `DataFeature`, but the user will
probably not [`apply`](@ref) these offsets manually, as this is handled by `FeatureQuery`
(via a call to [`observations`](@ref)).
