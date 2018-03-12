# Horizons

A [`Horizon`](@ref) is a composite type that allows the user to define the relationship
between the time at which a forecast runs (`sim_now`) and the target intervals of that
forecast.

These forecast targets will typically be `HourEnding` values, although other interval
types are also supported. See the [Intervals.jl documentation] for more information about
intervals.

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

julia> horizon = Horizon{HourEnding}(; span=Day(1))
Horizon{HourEnding{T} where T<:Base.Dates.TimeType}(1 day, 1 day, 0 hours)

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
 (2016-08-12 HE11-05:00]
 (2016-08-12 HE12-05:00]
 (2016-08-12 HE13-05:00]
 (2016-08-12 HE14-05:00]
 (2016-08-12 HE15-05:00]
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

> Are the values returned by `targets` always in hour ending format?

The format of the return value is determined `Horizon`'s type parameter, which defaults to
`HourEnding` if none is provided. However, it is possible to specify other interval types,
such as `HourBeginning`:

```jldoctest
julia> horizon = Horizon{HourBeginning}(; span=Day(1))
Horizon{HourBeginning{T} where T<:Base.Dates.TimeType}(1 day, 1 day, 0 hours)

julia> collect(targets(horizon, sim_now))
24-element Array{HourBeginning{TimeZones.ZonedDateTime},1}:
 [2016-08-12 HB00-05:00)
 [2016-08-12 HB01-05:00)
 [2016-08-12 HB02-05:00)
 [2016-08-12 HB03-05:00)
 [2016-08-12 HB04-05:00)
 [2016-08-12 HB05-05:00)
 [2016-08-12 HB06-05:00)
 [2016-08-12 HB07-05:00)
 [2016-08-12 HB08-05:00)
 [2016-08-12 HB09-05:00)
 [2016-08-12 HB10-05:00)
 [2016-08-12 HB11-05:00)
 [2016-08-12 HB12-05:00)
 [2016-08-12 HB13-05:00)
 [2016-08-12 HB14-05:00)
 [2016-08-12 HB15-05:00)
 [2016-08-12 HB16-05:00)
 [2016-08-12 HB17-05:00)
 [2016-08-12 HB18-05:00)
 [2016-08-12 HB19-05:00)
 [2016-08-12 HB20-05:00)
 [2016-08-12 HB21-05:00)
 [2016-08-12 HB22-05:00)
 [2016-08-12 HB23-05:00)
```

```@meta
DocTestSetup = nothing
```
