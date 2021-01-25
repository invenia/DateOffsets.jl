# [Date Offsets](@id date-offsets)

A [`DateOffset`](@ref) is a callable type that allows the user to construct the [observation interval](@ref observation-intervals) they wish to use in their model for a given `target`.
The relationship between the target and observation can also be defined by any function (or mapping) that takes [`OffsetOrigins`](@ref offsetorigins) as input and returns an `Interval`.

## [`OffsetOrigins`](@id offsetorigins)

The `OffsetOrigins` container stores the important timing information relevant to forecasting as intervals, namely, the `sim_now`, `bid_time` and the forecast `target`.
The `sim_now` and `target` are important because the [availability of data](@ref why-date-offsets) in production is usually bounded by one of these times, so they serve as useful "origins" for our offsets.

## The `DateOffset` Type

The relationship between a target interval and an observation interval is one-to-one, i.e. applying a single offset to a single target will return a single observation.

There are "standard" `DateOffsets` provided in this package that are used extensively in Production.
Users should make sure they are familiar with these [use cases](@ref use-cases) as they apply to our most commonly-used feeds.
These include:
* [`StaticOffset`](@ref)
* [`DynamicOffset`](@ref)
* [`FloorOffset`](@ref)

Additionally, the times defined in [`OffsetOrigins`](@ref offsetorigins) can also be used as "special" kinds of `DateOffsets`, since these are also frequently used:
* [`Target()`](@ref)
* [`SimNow()`](@ref)
* [`BidTime()`](@ref)

One or more [`DateOffset`](@ref)s must be defined for each `Feature`.
Users are not expected to apply these offsets manually as this is handled via a call to [`observations`](@ref) when the feature is fetched.

```@meta
DocTestSetup = quote
    using DateOffsets, TimeZones, Intervals, Dates, LaxZonedDateTimes

    # This is a hack to have nice printing that doesn't include module names.
    # https://github.com/JuliaDocs/Documenter.jl/issues/944
    @eval Main begin
        using DateOffsets, Intervals, TimeZones, Dates, LaxZonedDateTimes
    end

    sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
    target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
    origins = DateOffsets.OffsetOrigins(target, sim_now)
end
```

```jldoctest offsets
julia> using DateOffsets, Intervals, TimeZones, Dates

julia> sim_now = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
2016-08-11T02:00:00-05:00

julia> target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))

julia> origins = DateOffsets.OffsetOrigins(target, sim_now);

julia> StaticOffset(Day(-1))
StaticOffset(Target(), Day(-1))

julia> StaticOffset(Day(-1))(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
```

See the [examples](#examples) below and the [production use cases](@ref use-cases) for more information.

## Functions as Offsets

Sometimes, one might want to construct an offset that cannot be easily composed of the "standard" offsets described above.
For that purpose, offsets can also be defined as _functions_ that operate on [`OffsetOrigins`](@ref offsetorigins).
Users can thereby create their own mapping from the `sim_now` or `target` to the observation they want to create.

It is also helpful when nesting multiple `DateOffsets` (say, more than 3), since making a named function makes the logs easier to read.
This is shown by the following example:

```jldoctest offsets
julia> StaticOffset(FloorOffset(DynamicOffset(Target(); fallback=Day(-1), if_after=SimNow()), Hour), Hour(-1))
StaticOffset(FloorOffset(DynamicOffset(Target(), Day(-1), SimNow(), DateOffsets.always), Hour), Hour(-1))

julia> long_offset(o) = floor(dynamicoffset(o.target; fallback=Day(-1), if_after=o.sim_now), Hour) - Hour(1)
long_offset (generic function with 1 method)

julia> long_offset(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, tz"America/Winnipeg"))
```

## Examples

Below we illustrate examples of each kind of offset and why one might want to apply them.
In each case the `target` and `sim_now` are as follows, which are stored in `origins`.

```jldoctest examples
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))

julia> origins = DateOffsets.OffsetOrigins(target, sim_now);
```

### StaticOffset

A `StaticOffset` applies a fixed step to the offset origin.
In this case, we are applying a lag of 1 hour, which is applied to the target hour by default.

```jldoctest examples
julia> static_offset = StaticOffset(Hour(-1))
StaticOffset(Target(), Hour(-1))

julia> static_offset(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, tz"America/Winnipeg"))
```

### DynamicOffset

A `DynamicOffset` can be used when one wants apply a `fallback` step repeatedly until some special condition is met.
Here, we apply a `fallback` of 1 week for all targets that occur _after_ the `SimNow()`.
Note there is also a `match` keyword argument that one can use to define an additional condition to be met, e.g. `match=t->isaweekend(t)`.

```jldoctest examples
julia> match_hourofweek = DynamicOffset(; if_after=SimNow(), fallback=Week(-1))
DynamicOffset(Target(), Week(-1), SimNow(), DateOffsets.always)

julia> match_hourofweek(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 5, 1, tz"America/Winnipeg"))
```

### FloorOffset

A `FloorOffset` simply rounds the offset origin to the nearest time interval.
Here, we are rounding the target to the nearest day.

```jldoctest examples
julia> flooredtarget = FloorOffset(Target(), Day)
FloorOffset(Target(), Day)

julia> flooredtarget(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, tz"America/Winnipeg"))
```

### CustomOffset

The above examples are typical of the offsets used in our forecasters based on the features that are currently used in production.
Users may wish to generate different offsets to be used with new features.
To do this, one should define a named function that takes as input an [`OffsetOrigins`](@ref offsetorigins) and returns an `Interval`.

Here, the offset function returns the target if the `sim_now` is earlier than 6pm, else it returns the `sim_now` rounded up to the nearest hour.

```jldoctest examples
julia> offset_fn(o) = (hour(last(o.sim_now)) ≥ 18) ? HourEnding(ceil(o.sim_now, Hour)) : o.target
offset_fn (generic function with 1 method)

julia> offset_fn(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
```

```@meta
DocTestSetup = nothing
```
