# Source Offsets

A `SourceOffset` is an abstract type that allows the user to define the relationship
between a forecast target date (or `sim_now`) and the date associated with the input data
used to generate that forecast (also called the "observation date").

## Types

```
abstract DateOffset
    abstract SourceOffset
        immutable ScalarOffset
        immutable StaticOffset
        immutable LatestOffset
        immutable DynamicOffset
        immutable CustomOffset
    immutable CompoundOffset
```

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
    using DateOffsets, TimeZones, Base.Dates
    sim_now = ZonedDateTime(2016, 8, 11, 2, 30, TimeZone("America/Winnipeg"))
    latest_available = ZonedDateTime(2016, 8, 11, 2, TimeZone("America/Winnipeg"))
    target_date = ZonedDateTime(2016, 8, 12, 1, TimeZone("America/Winnipeg"))
end
```

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, TimeZone("America/Winnipeg"))
2016-08-11T02:30:00-05:00

julia> latest_available = ZonedDateTime(2016, 8, 11, 2, TimeZone("America/Winnipeg"))
2016-08-11T02:00:00-05:00

julia> target_date = ZonedDateTime(2016, 8, 12, 1, TimeZone("America/Winnipeg"))
2016-08-12T01:00:00-05:00
```

### StaticOffset

```jldoctest
julia> static_offset = StaticOffset(Hour(-1))
StaticOffset(-1 hour)

julia> apply(static_offset, target_date)
2016-08-12T00:00:00-05:00
```

### LatestOffset

```jldoctest
julia> latest_offset = LatestOffset()
LatestOffset()

julia> apply(latest_offset, target_date, latest_available, sim_now)
2016-08-11T02:00:00-05:00
```

### DynamicOffset

```jldoctest
julia> match_hourofweek = DynamicOffset(; fallback=Week(-1))
DynamicOffset(-1 week, DateOffsets.#4)

julia> apply(match_hourofweek, target_date, latest_available, sim_now)
2016-08-05T01:00:00-05:00
```

### CustomOffset

```jldoctest
julia> offset_fn(sim_now, target) = (hour(sim_now) ≥ 18) ? sim_now : target
offset_fn (generic function with 1 method)

julia> custom_offset = CustomOffset(offset_fn)
CustomOffset(offset_fn)

julia> apply(custom_offset, target_date, latest_available, sim_now)
2016-08-12T01:00:00-05:00
```

### CompoundOffset

```jldoctest
julia> compound_offset = DynamicOffset(; fallback=Week(-1)) + StaticOffset(Hour(-1))
CompoundOffset(DynamicOffset(-1 week, DateOffsets.#4), StaticOffset(-1 hour))

julia> apply(compound_offset, target_date, latest_available, sim_now)
2016-08-05T00:00:00-05:00
```

```@meta
DocTestSetup = nothing
```

## FAQ

> What is `latest_available`? Where does it come from?

Essentially, it represents the most recent available data (for a given data source) as of
`sim_now`, and it is calculated by pulling metadata from
[S3DB](https://gitlab.invenia.ca/invenia/S3DB.jl). For most users, who will be `apply`ing
all of their offsets via `DataFeature` and `FeatureQuery`, it will be calculated
automatically.
