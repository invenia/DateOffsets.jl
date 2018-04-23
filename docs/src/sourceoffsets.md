# Source Offsets

A `SourceOffset` is an abstract type that allows the user to define the relationship
between a forecast target (or `sim_now`) and the date interval associated with the input
data used to generate that forecast (also called the "observation date" or "observation
interval").

## Types

* `DateOffset` (abstract)
    * `SourceOffset` (abstract)
        * `ScalarOffset` (abstract)
            * `StaticOffset`
            * `LatestOffset`
            * `DynamicOffset`
            * `CustomOffset`
        * `CompoundOffset`

## API

```@docs
StaticOffset
LatestOffset
DynamicOffset
CustomOffset
CompoundOffset
apply
```

Any new subtype of `SourceOffset` should implement [`apply`](@ref) with the appropriate
signature.

## Examples

```@meta
DocTestSetup = quote
    using DateOffsets, TimeZones, Intervals, Base.Dates
    sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
    content_end = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
    target = HE(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
end
```

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> content_end = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
2016-08-11T02:00:00-05:00

julia> target = HE(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
HourEnding{TimeZones.ZonedDateTime}(2016-08-12T01:00:00-05:00, Inclusivity(false, true))
```

### StaticOffset

```jldoctest
julia> static_offset = StaticOffset(Hour(-1))
StaticOffset(-1 hour)

julia> apply(static_offset, target)
HourEnding{TimeZones.ZonedDateTime}(2016-08-12T00:00:00-05:00, Inclusivity(false, true))
```

### LatestOffset

```jldoctest
julia> latest_offset = LatestOffset()
LatestOffset()

julia> apply(latest_offset, target, content_end, sim_now)
HourEnding{TimeZones.ZonedDateTime}(2016-08-11T02:00:00-05:00, Inclusivity(false, true))
```

### DynamicOffset

```jldoctest
julia> match_hourofweek = DynamicOffset(; fallback=Week(-1))
DynamicOffset(-1 week, DateOffsets.#4)

julia> apply(match_hourofweek, target, content_end, sim_now)
HourEnding{TimeZones.ZonedDateTime}(2016-08-05T01:00:00-05:00, Inclusivity(false, true))
```

### CustomOffset

```jldoctest
julia> offset_fn(sim_now, target) = (hour(sim_now) ≥ 18) ? HE(sim_now) : target
offset_fn (generic function with 1 method)

julia> custom_offset = CustomOffset(offset_fn)
CustomOffset(offset_fn)

julia> apply(custom_offset, target, content_end, sim_now)
HourEnding{TimeZones.ZonedDateTime}(2016-08-12T01:00:00-05:00, Inclusivity(false, true))
```

### CompoundOffset

```jldoctest
julia> compound_offset = DynamicOffset(; fallback=Week(-1)) + StaticOffset(Hour(-1))
CompoundOffset(DynamicOffset(-1 week, DateOffsets.#4), StaticOffset(-1 hour))

julia> apply(compound_offset, target, content_end, sim_now)
HourEnding{TimeZones.ZonedDateTime}(2016-08-05T00:00:00-05:00, Inclusivity(false, true))
```

```@meta
DocTestSetup = nothing
```

## FAQ

> When I'm building a [`DataFeature`](https://doc.invenia.ca/invenia/DataFeatures.jl/master/types.html),
> I already have to specify a `sim_now`, a `horizon`, and a `window`. What are
> `SourceOffset`s even for?

Let's assume that you are defining a `DataFeature` without any `SourceOffset`s,
which might look something like this:

```julia
source = DataSource(S3DB.Client(), "ercot", "realtime_lmp")
filter = Dict("tag" => ["HTTPFinal"], "object_id" => ["AEEC"])
feature = DataFeature(source, filter, StaticOffset(Hour(0)))
query = FeatureQuery(feature, Horizon(), now(tz"America/Winnipeg"))
```

When you `fetch(query)`, you'll get a single `realtime_lmp` value for the AEEC object for
every target date (since you used `now` and the default `Horizon` constructor, that means
every hour of tomorrow in local Winnipeg time). Each realtime LMP value for AEEC will be
the value recorded in S3DB for that time.

However, suppose you add another couple of `SourceOffset`s, like this:

```julia
feature = DataFeature(source, filter, StaticOffset(Hour(0)), StaticOffset(Day(-1)), DynamicOffset(fallback=Week(-1)))
query = FeatureQuery(feature, Horizon(), now(tz"America/Winnipeg"))
```

Now if you `fetch(query)`, for each of the 24 target dates you'll get three values
(observations) back: one for that target date, one for that target date minus one day, and
one for the latest date/time (at or earlier than the target date) that is the same hour of
week as the target date but that is also "available" at `sim_now`.

> What is `content_end`? Where does it come from?

Essentially, it represents the most recent available data (for a given data source) as of
`sim_now`, and it is calculated by pulling metadata from [S3DB](https://gitlab.invenia.ca/invenia/S3DB.jl).
For most users, who will be `apply`ing all of their offsets via `DataFeature` and
`FeatureQuery`, it will be calculated automatically.
