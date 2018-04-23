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
    using DateOffsets, Intervals, TimeZones, Base.Dates
end
```

### Basic Constructor

```jldoctest
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

## FAQ

> Why not just use a vector of `Period`s (like `Hour(1):Hour(24)`) to represent the
> relationship between `sim_now` and the targets?

Because the relationship is more complex than one might initially guess. (Take a look at
the `start_ceil` and `start_offset` keyword arguments for the constructor, for example.)

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
Horizon(15 minutes, 4 hours, 1 day, 0 hours)

julia> collect(targets(horizon, sim_now))
16-element Array{AnchoredInterval{-15 minutes, TimeZones.ZonedDateTime},1}:
 (2016-08-12 15ME00:15-05:00]
 (2016-08-12 15ME00:30-05:00]
 (2016-08-12 15ME00:45-05:00]
 (2016-08-12 15ME01:00-05:00]
 (2016-08-12 15ME01:15-05:00]
 (2016-08-12 15ME01:30-05:00]
 (2016-08-12 15ME01:45-05:00]
 (2016-08-12 15ME02:00-05:00]
 (2016-08-12 15ME02:15-05:00]
 (2016-08-12 15ME02:30-05:00]
 (2016-08-12 15ME02:45-05:00]
 (2016-08-12 15ME03:00-05:00]
 (2016-08-12 15ME03:15-05:00]
 (2016-08-12 15ME03:30-05:00]
 (2016-08-12 15ME03:45-05:00]
 (2016-08-12 15ME04:00-05:00]
```

```@meta
DocTestSetup = nothing
```
