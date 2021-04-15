# [Horizons](@id horizons)

A [`Horizon`](@ref) is a composite type that allows the user to define the relationship between the time at which a forecast runs (`sim_now`) and the target intervals of that forecast.
The value returned by [`targets`](@ref) will typically be [`HourEnding`](https://invenia.github.io/Intervals.jl/stable/#HourEnding-and-HE-1) intervals, although other types are also supported.
See the [Intervals.jl documentation](https://invenia.github.io/Intervals.jl/stable/) for more information.

## The Horizon Type

The relationship between `sim_now` and the targets is one-to-many, e.g. for a single `sim_now` you will usually generate 24 target hours for the following day.
This is determined by the optional `step` and `span` keyword arguments passed into the `Horizon` constructor, which default to `step=Hour(1)`, `span=Day(1)`.
However, it is possible to specify other values, e.g. `step=Day(1)`.

Although our typical use case covers one day at one hour resolution, the behaviour can be more complex than one might initially guess.
For instance, since many markets observe Daylight Savings Time (DST), it means 23 or 25 hours will be generated at the DST transitions.
Furthermore, defining when the targets actually _start_ relative to the `sim_now` is not governed by a fixed offset but by the `start_fn` argument for the constructor.

[`Horizon`](@ref) takes care of this variability behind the scenes so you don't have to.

## Example

In this example we construct the default `Horizon`, which spans 1 day in steps of 1 hour, thereby creating 24 target intervals.

```@meta
DocTestSetup = quote
    using DateOffsets, Intervals, TimeZones, Dates

    # This is a hack to have nice printing that doesn't include module names.
    # https://github.com/JuliaDocs/Documenter.jl/issues/944
    @eval Main begin
        using DateOffsets, Intervals, TimeZones, Dates
    end
end
```

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; step=Hour(1), span=Day(1))  # 24 target interval spanning 1 day
Horizon(step=Hour(1), span=Day(1))

julia> collect(targets(horizon, sim_now))
24-element Vector{HourEnding{ZonedDateTime, Open, Closed}}:
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 2, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 3, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 4, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 5, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 6, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 7, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 8, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 9, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 10, tz"America/Winnipeg"))
 ⋮
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 16, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 17, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 18, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 19, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 20, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 21, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 22, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 12, 23, tz"America/Winnipeg"))
 HourEnding{ZonedDateTime, Open, Closed}(ZonedDateTime(2016, 8, 13, tz"America/Winnipeg"))
```

```@meta
DocTestSetup = nothing
```
