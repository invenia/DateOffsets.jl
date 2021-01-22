# [Production Use Cases](@id use-cases)

Below are some examples of how `DateOffsets` are used in practice in Invenia packages.

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

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> target = HourEnding(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))

julia> origins = DateOffsets.OffsetOrigins(target, sim_now);

```
## Use Case 1: Dayahead Load in [GPForecasters](https://invenia.pages.invenia.ca/GPForecasters.jl/)

The simplest usage of `DateOffsets` is in GPForecasters which naively fetches its features and filters them afterwards.
The dayahead load table consists of forecasts so we can depend on it to always have values for all hours of the target day.
Therefore we can use [`Target`](@ref) to check the presently available data.

```jldoctest
julia> load_offset = Target()
Target()

julia> load_offset(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
```

Similar offsets can be seen throughout our packages.

## Use Case 2: Dayahead Price and Realtime Price in [NodeSelection](https://invenia.pages.invenia.ca/NodeSelection.jl/)

In NodeSelection.jl, we are interested in cliquing the nodes based on the correlation of their delta LMPs (dayahead - realtime).
Although the markets publish the dayahead price for the whole day, the realtime price is only available up to `sim_now`.
However, we can't use the dayahead data if we don't have realtime data to match it since this would involve taking a dayahead value for one day and matching it with the realtime value for the day before.
We want the deltas to be computed using the _same hours_ for dayahead and realtime so we have to use the same offsets for both.

In contrast to price forecasters, cliquing is only performed _once_ for a target day and not for every hour.
Hence, the horizon we would use is a `Horizon(step=Day(1), span=Day(1))`, for which we want access to the latest N hours of available data for realtime price and dayahead price.
For this we use the a [`FloorOffset`](@ref) applied to [`SimNow`](@ref) combined with the required [`StaticOffset`](@ref)(s).

```jldoctest
julia> price_offsets = StaticOffset.(FloorOffset(SimNow()), Hour(0):Hour(-1):Hour(-72 * 24 - 1));

julia> price_offsets[1]
StaticOffset(FloorOffset(SimNow(), Hour), Hour(0))

julia> map(p->p(origins), price_offsets)
1730-element Array{AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed},1}:
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 2, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 23, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 22, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 21, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 20, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 19, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 18, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 17, tz"America/Winnipeg"))
 ⋮
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 9, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 8, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 7, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 6, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 5, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 4, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 3, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 2, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 5, 31, 1, tz"America/Winnipeg"))
```

### Use Case 3: `realtime_marketwide` in [PortfolioNets](https://invenia.pages.invenia.ca/PortfolioNets.jl/)

As the realtime market gets scheduled every 5-15 minutes, we only have data for the realtime marketwide (MEC) up to `sim_now`.

Imagine we wanted to map the 24 target hours to closest observations for the same hour of day where data is available.
For the targets where the hour of day is before the `sim_now`, we can just use the data published on bid day since this is already published.
But for targets where the hour of day is _after_ the `sim_now`, data is not yet available, so we need to jump back again and use data from the _previous day_.

The way to do this is to apply a [`DynamicOffset`](@ref) (falling back 1 day) after the `sim_now`.

```jldoctest pn
julia> realtime_offset(o) = floor(dynamicoffset(o.target; fallback=Day(-1), if_after=o.sim_now), Hour);

julia> realtime_offset(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
```

It is important to note that, in this example, the rounding to the hour happens _after_ jumping back.
For example `late_target` below occurs 15 minutes after `sim_now` so we jump back an additional day even though `DateTime(2016, 8, 11, 2)` is earlier than `sim_now`.

```jldoctest pn
julia> late_target = HourEnding(ZonedDateTime(2016, 8, 12, 2, 45, tz"America/Winnipeg"))
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, 45, tz"America/Winnipeg"))

julia> realtime_offset(DateOffsets.OffsetOrigins(late_target, sim_now))
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 2, tz"America/Winnipeg"))
```

### Use Case 4: Dayahead Marketwide in [BidPricing](https://invenia.pages.invenia.ca/BidPricing.jl/)

Since BidPricing only uses the dayahead price and not the deltas, we have access to data for the _entire_ bid day, not just up to `sim_now`.
For a given target hour, we want to use the dayahead price from the same hour the day before. We can easily do this with just a [`StaticOffset`](@ref).

```jldoctest
julia> dayahead_offset = FloorOffset(StaticOffset(Day(-1)));

julia> dayahead_offset(origins)
AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 11, 1, tz"America/Winnipeg"))
```

However, if the previous day's hour does not have data or does not exist due to DST, we want to jump back an additional day. 
So we add a [`DynamicOffset`](@ref) but convert it to a function to avoid a long type when logging:

```jldoctest bidpricing
julia> dayahead_offset(o) = floor(dynamicoffset(o.target - Day(1); fallback=Day(-1), match=isvalid, if_after=o.target), Hour);
```
On a normal day it jumps back a day.

```jldoctest bidpricing
julia> lax_target = HourEnding(LaxZonedDateTime(anchor(target)))
AnchoredInterval{Hour(-1),LaxZonedDateTime,Open,Closed}(2016-08-12T01:00:00-05:00)

julia> dayahead_offset(DateOffsets.OffsetOrigins(lax_target, sim_now))
AnchoredInterval{Hour(-1),LaxZonedDateTime,Open,Closed}(2016-08-11T01:00:00-05:00)
```

On the day after daylight savings it jumps back 2 days.

```jldoctest bidpricing
julia> dst_day = HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), tz"America/Winnipeg"))
AnchoredInterval{Hour(-1),LaxZonedDateTime,Open,Closed}(2016-03-13T02:00:00-DNE)

julia> dayahead_offset(DateOffsets.OffsetOrigins(dst_day + Day(1), sim_now))
AnchoredInterval{Hour(-1),LaxZonedDateTime,Open,Closed}(2016-03-12T02:00:00-06:00)
```

Note that the DST offset must be applied after the `StaticOffset` or we will simply step back to the invalid hour.

```jldoctest bidpricing
julia> wrong_offset(o) = floor(dynamicoffset(o.target; fallback=Day(-1), match=t->isvalid(t), if_after=o.target) - Day(1), Hour);

julia> wrong_offset(DateOffsets.OffsetOrigins(dst_day + Day(1), sim_now))
AnchoredInterval{Hour(-1),LaxZonedDateTime,Open,Closed}(2016-03-13T02:00:00-DNE)
```

```@meta
DocTestSetup = nothing
```
