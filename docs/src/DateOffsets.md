# DateOffsets.jl

```@meta
CurrentModule = DateOffsets
```

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
forecast runs (`sim_now`) and the target dates of that forecast.

The relationship between `sim_now` and the target dates is one-to-many.

```jldoctest
julia> using DateOffsets, TimeZones, Base.Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, TimeZone("America/Winnipeg"))
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; coverage=Day(1), step=Hour(1))
Horizon{Base.Dates.Hour}(1 day at 1 hour resolution)

julia> targets(horizon, sim_now)
2016-08-12T01:00:00-05:00:1 hour:2016-08-13T00:00:00-05:00
```

### SourceOffset Type

[Source Offsets](@ref) allow the user to define the relationship between a forecast
target date (or `sim_now`) and the date associated with the input data used to generate
that forecast (also called the "observation date").

The relationship between a target date and an observation date is one-to-one (applying
a single offset to a single target date will return a single observation date).

```jldoctest
julia> using DateOffsets, TimeZones, Base.Dates

julia> target_date = ZonedDateTime(2016, 8, 12, 1, TimeZone("America/Winnipeg"))
2016-08-12T01:00:00-05:00

julia> static_offset = StaticOffset(Day(-1))
StaticOffset(-1 day)

julia> apply(static_offset, target_date)
2016-08-11T01:00:00-05:00
```

One or more `SourceOffset`s must be defined for each `DataFeature`, but the user will
probably not [`apply`](@ref) these offsets manually, as this is handled by `FeatureQuery`
(via a call to [`observations`](@ref)).
