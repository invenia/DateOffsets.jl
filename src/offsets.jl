"""
    DateOffset

A callable type that takes an [`OffsetOrigins`](@ref) and returns a single `AnchoredInterval`.
Used to determine the observations to query for model training.

It is preferred to use named functions over `DateOffsets` for any complex calculations.
`DateOffsets` are preferred over anonymous functions in order to keep the logs readable.
"""
abstract type DateOffset end

Base.broadcastable(a::DateOffset) = Ref(a)

const SourceOffset = Union{Function, DateOffset}

"""
    OffsetOrigins{T}(target::T, sim_now::T) where T::AnchoredInterval
    OffsetOrigins(
        target::AnchoredInterval,
        sim_now::NowType
    )

Construct a container for the specific times from which any offset can be defined,
namely: the `target` and `sim_now`.

Observation intervals are computed by applying the `DateOffset` to the origin.
"""
struct OffsetOrigins{T<:AnchoredInterval}
    target::T
    sim_now::T
end

function OffsetOrigins(
    target::T,
    sim_now::NowType,
) where T <: AnchoredInterval
    OffsetOrigins(target, T(sim_now))
end

"""
    dynamicoffset(
        target::$TargetType;
        fallback::Period=Day(-1),
        if_after=target,
        match=always
    )

Take steps of `fallback` size away from the `target` until the resulting value
returns `true` when given to `match` and is less than or equal to `if_after`.
"""
function dynamicoffset(target::TargetType; fallback::Period=Day(-1), if_after=target, match=always)
    T = typeof(target)
    criteria = t -> t <= anchor(if_after) && match(t)
    offset = toprev(criteria, last(target); step=fallback, same=true)
    return T(offset)
end

"""
    SimNow()

Create a callable object. When applied to an `OffsetOrigins`, the object returns the `sim_now`.
"""
struct SimNow <: DateOffset end
(::SimNow)(o::OffsetOrigins) = o.sim_now

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

Create a callable object. Applies [`dynamicoffset`](@ref) to an `OffsetOrigins`, to create
the observation interval.

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

Create a callable object. When applied to an `OffsetOrigins`, the
object adds the `period` to the result from `origin` to create the observation interval.

It is preferred to create a named function instead of a using StaticOffset in situations where
`origin` is not an accessor to a field in `OffsetOrigins`.
"""
struct StaticOffset <: DateOffset
    origin::SourceOffset
    period::Period
end
StaticOffset(period::Period) = StaticOffset(Target(), period)
(offset::StaticOffset)(o::OffsetOrigins) = offset.origin(o) + offset.period

"""
    FloorOffset(origin::Function=Target(), T::Type=Hour)

Create a callable object. When applied to an `OffsetOrigins`, the object floors
an `AnchoredInterval` result from `origin` to create the observation interval.
"""
struct FloorOffset <: DateOffset
    origin::SourceOffset
    T::Type

    FloorOffset(origin, T=Hour) = new(origin, T)
end
(offset::FloorOffset)(o::OffsetOrigins) = floor(offset.origin(o), offset.T)
