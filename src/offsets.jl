"""
    DateOffset

A callable type that takes an [`OffsetOrigins`](@ref) and returns a single `AnchoredInterval`.
Used to determine the observation intervals for time-series forecasting.

To keep logs readable, it is preferred to use named functions over nesting multiple (3+)
`DateOffsets`. Similarly, anonymous functions are not advised.
"""
abstract type DateOffset end

Base.broadcastable(a::DateOffset) = Ref(a)

const SourceOffset = Union{Function, DateOffset}

"""
    OffsetOrigins{T}(target::T, sim_now::T) where T::AnchoredInterval
    OffsetOrigins(
        target::AnchoredInterval,
        sim_now::NowType
        bid_time::NowType
    )

Construct a container for the specific times from which any offset can be defined,
namely: the `target`, `sim_now` and `bid_time`.

Observation intervals are computed by applying the `DateOffset` to the origin.
"""
struct OffsetOrigins{T<:AnchoredInterval}
    target::T
    sim_now::T
    bid_time::T
end

function OffsetOrigins(
    target::T,
    sim_now::NowType,
    bid_time::NowType=sim_now,
) where T <: AnchoredInterval
    OffsetOrigins(target, T(sim_now), T(bid_time))
end

"""
    dynamicoffset(
        target::$TargetType;
        fallback::Period=Day(-1),
        if_after=target,
        match=always
    )

Take steps of `fallback` size away from the `target` if it occurs later than `if_after` and
until the resulting value returns `true` when given to `match`.
"""
function dynamicoffset(target::TargetType; fallback::Period=Day(-1), if_after=target, match=always)
    T = typeof(target)
    criteria = t -> t <= anchor(if_after) && match(t)
    offset = toprev(criteria, last(target); step=fallback, same=true)
    return T(offset)
end

"""
    SimNow()

Create a callable object.
When applied to an `OffsetOrigins`, the object returns the `sim_now` of the training day
(the `bid_time` offset by the query `window`).
"""
struct SimNow <: DateOffset end
(::SimNow)(o::OffsetOrigins) = o.sim_now

"""
    BidTime()

Create a callable object.
When applied to an `OffsetOrigins`, the object returns the `bid_time` for the query
(the simulated time at which the entire query is run).
"""
struct BidTime <: DateOffset end
(::BidTime)(o::OffsetOrigins) = o.bid_time

"""
    Target()

Create a callable object. When applied to an `OffsetOrigins`, the object returns the `target`.
"""
struct Target <: DateOffset end
(::Target)(o::OffsetOrigins) = o.target

struct DynamicOffset <: DateOffset
    target::SourceOffset
    fallback::Period
    if_after::Union{SourceOffset, TargetType}
    match::Function
end

"""
    DynamicOffset(
        target::Function=Target();
        fallback::Period=Day(-1),
        if_after::Function=Target(),
        match::Function=alwaysmatch
    )

Create a callable object that applies [`dynamicoffset`](@ref) to an `OffsetOrigins`, by
default the [`Target`](@ref), to create the observation interval.

It is preferred to create a named function containing [`dynamicoffset`](@ref) instead of
using a `DynamicOffset` in situations where several `DateOffsets` would otherwise be nested.
"""
function DynamicOffset(
    target=Target();
    fallback=Day(-1),
    if_after=Target(),
    match=always
)
    fallback < zero(fallback) || throw(ArgumentError("Fallback must be negative."))
    return DynamicOffset(target, fallback, if_after, match)
end

function (offset::DynamicOffset)(o::OffsetOrigins)
    return dynamicoffset(
        offset.target(o);
        fallback=offset.fallback,
        if_after=offset.if_after(o),
        match=offset.match,
    )
end

"""
    StaticOffset([origin::SourceOffset], period::Period)

Create a callable object. When applied to an `OffsetOrigins` it adds the `period` to the
result from `origin`, by default the [`Target`](@ref), to create the observation interval.

It is preferred to create a named function instead of a using StaticOffset in situations
where `origin` is not an accessor to a field in `OffsetOrigins`.
"""
struct StaticOffset <: DateOffset
    origin::SourceOffset
    period::Period
end
StaticOffset(period::Period) = StaticOffset(Target(), period)
(offset::StaticOffset)(o::OffsetOrigins) = offset.origin(o) + offset.period

"""
    FloorOffset(origin::Function=Target(), T::Type=Hour)

Create a callable object. When applied to an `OffsetOrigins`, the object floors result from
`origin` to create the observation interval.
"""
struct FloorOffset <: DateOffset
    origin::SourceOffset
    T::Type

    FloorOffset(origin, T=Hour) = new(origin, T)
end
(offset::FloorOffset)(o::OffsetOrigins) = floor(offset.origin(o), offset.T)
