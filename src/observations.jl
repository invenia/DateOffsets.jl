"""
    observations(
        offsets::Vector{<:SourceOffset},
        horizon::Horizon,
        sim_now::T,
    ) where T<:Union{ZonedDateTime, LaxZonedDateTime} -> (Vector{T}, Vector{T}, Matrix{T})

    observations(
        offsets::Vector{<:SourceOffset},
        horizon::Horizon,
        sim_now::Vector{T},
    ) where T<:Union{ZonedDateTime, LaxZonedDateTime} -> (Vector{T}, Vector{T}, Matrix{T})

Generates forecast or training observation intervals for a single `sim_now` or series of
`sim_now`s and any number of `offsets`. This is accomplished by using the `horizon` to
generate target intervals for the `sim_now`, duplicating the targets for each element in
`offsets`, and applying each offset to its corresponding column of targets to produce the
observation intervals.

The return value is a tuple, the first element of which is a vector of `sim_now`s, the
second is a vector of target intervals, and the third is the matrix of observation
intervals. The vectors of `sim_now`s and targets are the same size (the `sim_now` that is
passed in is duplicated) and correspond row-wise to the matrix of observation intervals
(which will have one column for each element in the `offsets` vector).

## Example with a single sim_now

Expected results for the call below:

`s` and `t` would each have 24 elements (or maybe 23 or 25: one for each hour of the next
day) and `o` would be a 24x2 matrix. Each element of `s` would be equal to `sim_now`, and
the elements of `t` would be the target intervals returned by the call
`targets(horizon, sim_now)`. The first column of `o` would contain the values of `t` with
`marketwide_offset` applied, while the second would contain the values of `t` with a
`StaticOffset` of one day applied.

```@meta
DocTestSetup = quote
    using DateOffsets, Dates, Intervals, TimeZones
end
```

```jldoctest
julia> sim_now = ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")
2016-08-11T02:30:00-05:00

julia> marketwide_offset(o) = floor(dynamicoffset(o.target, if_after=o.sim_now), Hour)
marketwide_offset (generic function with 1 method)

julia> offsets = [marketwide_offset, StaticOffset(Day(1))]
2-element Array{Any,1}:
 marketwide_offset (generic function with 1 method)
 StaticOffset(Target(), Day(1))

julia> horizon = Horizon(; step=Hour(1), span=Day(1))
Horizon(step=Hour(1), span=Day(1))

julia> s, t, o = observations(offsets, horizon, sim_now);

julia> s
24-element Array{ZonedDateTime,1}:
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 ⋮
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00

julia> t
24-element Array{AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed},1}:
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 1, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 2, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 3, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 4, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 5, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 6, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 7, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 8, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 9, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 10, tz"America/Winnipeg"))
 ⋮
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 16, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 17, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 18, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 19, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 20, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 21, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 22, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 23, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 13, tz"America/Winnipeg"))

julia> o
24×2 Array{AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed},2}:
 (2016-08-11 HE01-05:00]  (2016-08-13 HE01-05:00]
 (2016-08-11 HE02-05:00]  (2016-08-13 HE02-05:00]
 (2016-08-10 HE03-05:00]  (2016-08-13 HE03-05:00]
 (2016-08-10 HE04-05:00]  (2016-08-13 HE04-05:00]
 (2016-08-10 HE05-05:00]  (2016-08-13 HE05-05:00]
 (2016-08-10 HE06-05:00]  (2016-08-13 HE06-05:00]
 (2016-08-10 HE07-05:00]  (2016-08-13 HE07-05:00]
 (2016-08-10 HE08-05:00]  (2016-08-13 HE08-05:00]
 (2016-08-10 HE09-05:00]  (2016-08-13 HE09-05:00]
 (2016-08-10 HE10-05:00]  (2016-08-13 HE10-05:00]
 ⋮
 (2016-08-10 HE16-05:00]  (2016-08-13 HE16-05:00]
 (2016-08-10 HE17-05:00]  (2016-08-13 HE17-05:00]
 (2016-08-10 HE18-05:00]  (2016-08-13 HE18-05:00]
 (2016-08-10 HE19-05:00]  (2016-08-13 HE19-05:00]
 (2016-08-10 HE20-05:00]  (2016-08-13 HE20-05:00]
 (2016-08-10 HE21-05:00]  (2016-08-13 HE21-05:00]
 (2016-08-10 HE22-05:00]  (2016-08-13 HE22-05:00]
 (2016-08-10 HE23-05:00]  (2016-08-13 HE23-05:00]
 (2016-08-10 HE24-05:00]  (2016-08-13 HE24-05:00]

```

## Example with multiple sim_nows

Expected results for the call below:

`s` and `t` would each have 72 elements (±1: one for each hour of each of the three day
period) and `o` would be a 72x2 matrix. Each element of `s` would be equal to one of the
three `sim_now`s, and the elements of `t` would be the target intervals returned by calling
`targets(horizon, sim_now)` for each `sim_now`. The first column of `o` would contain the
values of `t` with `marketwide_offset` applied, while the second would contain the values of `t`
with a `StaticOffset` of one day applied.

```jldoctest
julia> marketwide_offset(o) = floor(dynamicoffset(o.target, if_after=o.sim_now), Hour)
marketwide_offset (generic function with 1 method)

julia> offsets = [marketwide_offset, StaticOffset(Day(1))]
2-element Array{Any,1}:
 marketwide_offset (generic function with 1 method)
 StaticOffset(Target(), Day(1))

julia> horizon = Horizon(; step=Hour(1), span=Day(1))
Horizon(step=Hour(1), span=Day(1))

julia> sim_now = [ZonedDateTime(2016, 8, 11, 2, 30, tz"America/Winnipeg")] .- [Day(2), Day(1), Day(0)]
3-element Array{ZonedDateTime,1}:
 2016-08-09T02:30:00-05:00
 2016-08-10T02:30:00-05:00
 2016-08-11T02:30:00-05:00

julia> s, t, o = observations(offsets, horizon, sim_now);

julia> s
72-element Array{ZonedDateTime,1}:
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 2016-08-09T02:30:00-05:00
 ⋮
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00
 2016-08-11T02:30:00-05:00

julia> t
72-element Array{AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed},1}:
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 1, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 2, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 3, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 4, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 5, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 6, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 7, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 8, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 9, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 10, 10, tz"America/Winnipeg"))
 ⋮
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 16, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 17, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 18, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 19, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 20, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 21, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 22, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 12, 23, tz"America/Winnipeg"))
 AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed}(ZonedDateTime(2016, 8, 13, tz"America/Winnipeg"))

julia> o
72×2 Array{AnchoredInterval{Hour(-1),ZonedDateTime,Open,Closed},2}:
 (2016-08-09 HE01-05:00]  (2016-08-11 HE01-05:00]
 (2016-08-09 HE02-05:00]  (2016-08-11 HE02-05:00]
 (2016-08-08 HE03-05:00]  (2016-08-11 HE03-05:00]
 (2016-08-08 HE04-05:00]  (2016-08-11 HE04-05:00]
 (2016-08-08 HE05-05:00]  (2016-08-11 HE05-05:00]
 (2016-08-08 HE06-05:00]  (2016-08-11 HE06-05:00]
 (2016-08-08 HE07-05:00]  (2016-08-11 HE07-05:00]
 (2016-08-08 HE08-05:00]  (2016-08-11 HE08-05:00]
 (2016-08-08 HE09-05:00]  (2016-08-11 HE09-05:00]
 (2016-08-08 HE10-05:00]  (2016-08-11 HE10-05:00]
 ⋮
 (2016-08-10 HE16-05:00]  (2016-08-13 HE16-05:00]
 (2016-08-10 HE17-05:00]  (2016-08-13 HE17-05:00]
 (2016-08-10 HE18-05:00]  (2016-08-13 HE18-05:00]
 (2016-08-10 HE19-05:00]  (2016-08-13 HE19-05:00]
 (2016-08-10 HE20-05:00]  (2016-08-13 HE20-05:00]
 (2016-08-10 HE21-05:00]  (2016-08-13 HE21-05:00]
 (2016-08-10 HE22-05:00]  (2016-08-13 HE22-05:00]
 (2016-08-10 HE23-05:00]  (2016-08-13 HE23-05:00]
 (2016-08-10 HE24-05:00]  (2016-08-13 HE24-05:00]

```

```@meta
DocTestSetup = nothing
```
"""
function observations(
    offsets::Vector,
    horizon::Horizon,
    sim_now::NowType,
)
    t = collect(targets(horizon, sim_now))
    o = repeat(t; outer=(1, length(offsets)))
    for (i, offset) in enumerate(offsets)
        o[:, i] = map(dt -> offset(OffsetOrigins(dt, sim_now)), o[:, i])
    end

    return (fill(sim_now, length(t)), t, o)
end

function observations(
    offsets::Vector,
    horizon::Horizon,
    sim_now::Vector{<:NowType},
)
    tuple = map((s) -> observations(offsets, horizon, s), sim_now)

    return map((1, 2, 3)) do i
        mapreduce(x -> x[i], vcat, tuple)
    end
end
