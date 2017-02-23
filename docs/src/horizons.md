# Horizons

A [`Horizon`](@ref) is a composite type that allows the user to define the relationship
between the time at which a forecast runs (`sim_now`) and the target dates of that
forecast.

## API

```@docs
Horizon
targets
```

## Examples

```@meta
DocTestSetup = quote
    using DateOffsets, TimeZones, Base.Dates
end
```

### Basic Constructor

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, TimeZone("America/Winnipeg"))
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(; coverage=Day(1), step=Hour(1))
Horizon{Base.Dates.Hour}(1 day at 1 hour resolution)

julia> targets(horizon, sim_now)
2016-08-12T01:00:00-05:00:1 hour:2016-08-13T00:00:00-05:00
```

### Range Constructor

The user may also specify "old style" horizons (e.g. "two to eight hours ahead") using the
range constructor.

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, TimeZone("America/Winnipeg"))
2016-08-11T02:30:00-05:00

julia> horizon = Horizon(Hour(2):Hour(8))
Horizon{Base.Dates.Hour}(7 hours at 1 hour resolution, start date rounded up to 1 hour + 1 hour)

julia> targets(horizon, sim_now)
2016-08-11T05:00:00-05:00:1 hour:2016-08-11T11:00:00-05:00
```

```@meta
DocTestSetup = nothing
```

## FAQ

> Why not just use a vector of `Period`s (like `Hour(1):Hour(24)`) to represent the
> relationship between `sim_now` and the target dates?

Because the relationship is more complex than one might initially guess. (Take a look at
the `start_ceil` and `start_offset` keyword arguments for the constructor, for example.)

Additionally, our typical use case covers one day at one hour resolution. Since many
markets observe DST, this may mean 23 or 25 hours (and as of v0.5, Julia does not support
`Hour(1):Hour(1):Day(1)`).

> Are the target dates returned by `targets` in hour ending format?

Yes. All dates that are not instantaneous (e.g., target dates, observation dates) are in
period ending format. This means that `13:00` would represent the one hour period
`(12:00, 13:00]`.
