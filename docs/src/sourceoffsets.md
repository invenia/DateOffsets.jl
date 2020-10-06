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
            * `SimNowOffset`
            * `DynamicOffset`
            * `CustomOffset`
                * `AnchoredOffset`
        * `CompoundOffset`

## API

```@docs
StaticOffset
LatestOffset
SimNowOffset
DynamicOffset
CustomOffset
AnchoredOffset
CompoundOffset
LATEST_OFFSET
SIM_NOW_OFFSET
apply
```

Any new subtype of `SourceOffset` should implement [`apply`](@ref) with the appropriate
signature.

## Examples

```@meta
DocTestSetup = quote
    using DateOffsets, TimeZones, Intervals, Dates, LaxZonedDateTimes

    # This is a hack to have nice printing that doesn't include module names.
    # https://github.com/JuliaDocs/Documenter.jl/issues/944
    @eval Main begin
        using DateOffsets, Intervals, TimeZones, Dates, LaxZonedDateTimes
    end

    sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
    last_observation = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
    target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
end
```

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> last_observation = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
2016-08-11T02:00:00-05:00

julia> target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
```

### StaticOffset

```jldoctest
julia> static_offset = StaticOffset(Hour(-1))
StaticOffset(Hour(-1))

julia> apply(static_offset, target)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, tz"America/Winnipeg"))
```

### LatestOffset

```jldoctest
julia> latest_offset = LatestOffset()
LatestOffset()

julia> apply(latest_offset, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg"))
```

### DynamicOffset

```jldoctest
julia> match_hourofweek = DynamicOffset(; fallback=Week(-1))
DynamicOffset(fallback=Week(-1), match=DateOffsets.always)

julia> apply(match_hourofweek, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 5, 1, tz"America/Winnipeg"))
```

### CustomOffset

```jldoctest
julia> offset_fn(target, last_observation, sim_now) = (hour(sim_now) ≥ 18) ? HourEnding(ceil(sim_now, Hour)) : target
offset_fn (generic function with 1 method)

julia> custom_offset = CustomOffset(offset_fn)
CustomOffset(offset_fn)

julia> apply(custom_offset, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
```

### CompoundOffset

```jldoctest
julia> compound_offset = DynamicOffset(; fallback=Week(-1)) + StaticOffset(Hour(-1))
CompoundOffset(DynamicOffset(fallback=Week(-1), match=DateOffsets.always), StaticOffset(Hour(-1)))

julia> apply(compound_offset, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 5, tz"America/Winnipeg"))
```

## Use Cases

Below are some examples of how `DateOffsets` are used in practice in Invenia packages as of September 2020.

The `target`, `last_observation` and `sim_now` remain the same as the examples above.
```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> last_observation = ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg")
2016-08-11T02:00:00-05:00

julia> target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
```
### Use case 1: dayahead_load in [GPForecasters](https://invenia.pages.invenia.ca/GPForecasters.jl/)

The simplest usage of `DateOffsets` is in GPForecasters which naively fetches its features and filters them afterwards.
The `dayahead_load` table consists of forecasts so we can depend on it to always have values for all hours of the target day.
Therefore we can use a `StaticOffset` to check the presently available data.

```jldoctest
julia> load_offset = StaticOffset(Hour(0));

julia> apply(load_offset, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
```

Similar offsets can be seen throughout our packages.

### Use case 2: dayahead\_price and realtime\_price in [NodeSelection](https://invenia.pages.invenia.ca/NodeSelection.jl/)

In NodeSelection, we are interested in cliquing the nodes based on the correlation of their delta LMPs (dayahead - realtime).
As with `realtime_marketwide`, `realtime_price` is also only available up to `sim_now`.
Although the markets publish the `dayahead_price` for the whole day, we want the delta to be computed consistently for each hour so we have to use the same offsets for both.

In contrast to price forecasters, cliquing is only performed _once_ for a target day and not for every hour.
Hence, we want access to the latest N hours of available data for `realtime_price` and `dayahead_price`.
For this we use a [`SIM_NOW_OFFSET`](@ref) combined with the required [`StaticOffset`](@ref)(s).
```jldoctest
julia> price_offsets = SIM_NOW_OFFSET .+ StaticOffset.(Hour(0):Hour(-1):Hour(-72 * 24 - 1));

julia> apply.(price_offsets, target, last_observation, sim_now)
1730-element Array{AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed},1}:
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 23, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 22, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 21, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 20, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 19, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 18, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 17, tz"America/Winnipeg"))
 ⋮
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 9, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 8, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 7, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 6, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 5, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 4, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 3, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 2, tz"America/Winnipeg"))
 AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 1, tz"America/Winnipeg"))
```

### Use Case 3: realtime_marketwide in [PortfolioNets](https://invenia.pages.invenia.ca/PortfolioNets.jl/)

As the realtime market gets scheduled every 5-15 minutes, we should only have data for `realtime_marketwide` up to `sim_now`.
To use as much data as possible, we can select `realtime_marketwide` for the hours it has been published (up to `sim_now`), and for all hours after `sim_now` we use the data for the same hour from _yesterday_.

Hence, we want to apply a [`DynamicOffset`](@ref) (falling back 1 day) after the `sim_now`.
A way to do this is with an [`AnchoredOffset`](@ref) as follows.
```jldoctest pn
julia> realtime_offset = AnchoredOffset(DynamicOffset(; fallback=Day(-1)), :sim_now);

julia> apply(realtime_offset, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
```

It is important to note that the rounding to the hour happens _after_ jumping back.
For example `late_target` below occurs 15 minutes after `sim_now` so we jump back an additional day even though `DateTime(2016, 8, 11, 2)` is earlier than `sim_now`.
```jldoctest pn
julia> late_target = HourEnding(ZonedDateTime(2016, 8, 12, 2, 45, tz"America/Winnipeg"))
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, 45, tz"America/Winnipeg"))

julia> apply(realtime_offset, late_target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 2, tz"America/Winnipeg"))
```

### Use Case 4: dayahead_marketwide in [BidPricing](https://invenia.pages.invenia.ca/BidPricing.jl/)

Since BidPricing only uses the `dayahead_price` and not the deltas, we have access to data for the _entire_ bid day, not just up to `sim_now`.
For a given target hour, we want to use the dayahead price from the same hour the day before.We can easily do this with just a [`StaticOffset`](@ref).
We combine this with a [`AnchoredOffset`](@ref) to specify the `target` as the anchor point and disregard the `last_observation`.
```jldoctest
julia> dayahead_offset = AnchoredOffset(StaticOffset(Day(-1)), :target);

julia> apply(dayahead_offset, target, last_observation, sim_now)
AnchoredInterval{-1 hour,ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
```

However if the previous day's hour does not have data or does not exist due to DST, we want to jump back an additional day. So we add:
```jldoctest bidpricing
julia> dayahead_offset = AnchoredOffset(StaticOffset(Day(-1)) + DynamicOffset(;fallback=Day(-1), match=t->isvalid(t)), :target);
```
On a normal day it jumps back a day.
```jldoctest bidpricing
julia> lax_target = HourEnding(LaxZonedDateTime(anchor(target)))
AnchoredInterval{-1 hour,LaxZonedDateTime,Open,Closed}(2016-08-12T01:00:00-05:00)

julia> apply(dayahead_offset, lax_target, last_observation, sim_now)
AnchoredInterval{-1 hour,LaxZonedDateTime,Open,Closed}(2016-08-11T01:00:00-05:00)
```

On the day after daylight savings it jumps back 2 days.
```jldoctest bidpricing
julia> dst_day = HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), tz"America/Winnipeg"))
AnchoredInterval{-1 hour,LaxZonedDateTime,Open,Closed}(2016-03-13T02:00:00-DNE)

julia> apply(dayahead_offset, dst_day + Day(1), last_observation, sim_now)
AnchoredInterval{-1 hour,LaxZonedDateTime,Open,Closed}(2016-03-12T02:00:00-06:00)
```

Note that the DST offset must be applied after the `StaticOffset` or we will simply step back to the invalid hour.
```jldoctest bidpricing
julia> wrong_offset = DynamicOffset(;fallback=Day(-1), match=t->isvalid(t))+ StaticOffset(Day(-1));

julia> apply(wrong_offset, dst_day + Day(1), last_observation, sim_now)
AnchoredInterval{-1 hour,LaxZonedDateTime,Open,Closed}(2016-03-13T02:00:00-DNE)
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

> What is `last_observation`? Where does it come from?

Essentially, it represents the most recent available data (for a given data source) as of
`sim_now`, and it is calculated by pulling metadata from [S3DB](https://gitlab.invenia.ca/invenia/S3DB.jl).
For most users, who will be `apply`ing all of their offsets via `DataFeature` and
`FeatureQuery`, it will be calculated automatically.

