# Horizons

A [`Horizon`](@ref) is a composite type that allows the user to define the relationship
between the time at which a forecast runs (`sim_now`) and the target intervals of that
forecast.

These forecast targets will typically be `HourEnding` values, although other interval
types are also supported. See the [Intervals.jl documentation](https://invenia.github.io/Intervals.jl/stable/)
for more information about intervals.

## API

```@docs
Horizon
targets
```

## Examples

```@meta
DocTestSetup = quote
    using DateOffsets, Intervals, TimeZones, Dates
end
```

### Basic Constructor

```jldoctest
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

## FAQ

> Why not just use a vector of `Period`s (like `Hour(1):Hour(24)`) to represent the
> relationship between `sim_now` and the targets?

Because the relationship is more complex than one might initially guess. (Take a look at
the `start_fn` keyword argument for the constructor, for example.)

Additionally, our typical use case covers one day at one hour resolution. Since many
markets observe DST, this may mean 23 or 25 hours (and as of v0.6, Julia does not support
`Hour(1):Hour(1):Day(1)`).

Finally, such a vector would still result in `ZonedDateTime` values, rather than
`AnchoredInterval`s.

> Are the values returned by `targets` always in hour ending format?

The format of the return value is determined by the optional `step` keyword argument passed
into the `Horizon` constructor, which defaults to `Hour(1)` if none is provided. However, it
is possible to specify another value:

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; step=Minute(15), span=Hour(4))
Horizon(step=Minute(15), span=Hour(4))

julia> collect(targets(horizon, sim_now))
16-element Array{AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed},1}:
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 0, 15, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 0, 30, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 0, 45, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, 15, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, 30, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, 45, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, 15, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, 30, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, 45, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 3, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 3, 15, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 3, 30, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 3, 45, tz"America/Winnipeg"))
 AnchoredInterval{-15 minutes,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 4, tz"America/Winnipeg"))
```

```@meta
DocTestSetup = nothing
```
