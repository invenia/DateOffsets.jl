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

    # This is a hack to have nice printing that doesn't include module names.
    # https://github.com/JuliaDocs/Documenter.jl/issues/944
    @eval Main begin
        using DateOffsets, Intervals, TimeZones, Dates
    end
end
```

### Basic Constructor

```jldoctest
julia> using DateOffsets, Intervals, TimeZones, Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; step=Hour(1), span=Day(1))
Horizon(step=Hour(1), span=Day(1))

julia> collect(targets(horizon, sim_now))
24-element Array{AnchoredInterval{-1 hour,ZonedDateTime},1}:
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T01:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T02:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T03:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T04:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T05:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T06:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T07:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T08:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T09:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T10:00:00-05:00, Inclusivity(false, true))
 ⋮
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T16:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T17:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T18:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T19:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T20:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T21:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T22:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-12T23:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-1 hour,ZonedDateTime}(2016-08-13T00:00:00-05:00, Inclusivity(false, true))
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
16-element Array{AnchoredInterval{-15 minutes,ZonedDateTime},1}:
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T00:15:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T00:30:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T00:45:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T01:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T01:15:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T01:30:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T01:45:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T02:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T02:15:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T02:30:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T02:45:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T03:00:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T03:15:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T03:30:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T03:45:00-05:00, Inclusivity(false, true))
 AnchoredInterval{-15 minutes,ZonedDateTime}(2016-08-12T04:00:00-05:00, Inclusivity(false, true))
```

```@meta
DocTestSetup = nothing
```
