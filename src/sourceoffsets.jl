abstract type SourceOffset <: DateOffset end
abstract type ScalarOffset <: SourceOffset end

"""
    StaticOffset(period::Period) -> StaticOffset

Constructs a `StaticOffset`. When a `StaticOffset` is applied to a target interval, the
`period` is simply added to the target to create the observation interval.
"""
struct StaticOffset <: ScalarOffset
    period::Period
end

Base.isless(a::StaticOffset, b::StaticOffset) = isless(a.period, b.period)
Base.:-(a::StaticOffset) = (StaticOffset(-a.period))

function Base.show(io::IO, o::StaticOffset)
    print(io, "StaticOffset(")
    repr_period(io, o.period)
    print(io, ')')
end
Base.print(io::IO, o::StaticOffset) = print(io, o.period)

Base.:+(x::DateOffset, y::Period) = x + StaticOffset(y)
Base.:+(x::Period, y::DateOffset) = StaticOffset(x) + y
Base.:-(x::DateOffset, y::Period) = x - StaticOffset(y)
Base.:-(x::Period, y::DateOffset) = StaticOffset(x) - y

Base.isless(::SourceOffset, ::SourceOffset) = false

Base.broadcastable(a::StaticOffset) = Ref(a)

"""
    LatestOffset() -> LatestOffset

Constructs a `LatestOffset`. When a `LatestOffset` is applied to a target interval, metadata
associated with the appropriate `DataFeature` is checked to determine whether that data for
that target is expected to be available (for the `sim_now` provided).

If data for the target is expected to be available on S3DB at `sim_now`, that target
interval is returned as the observation interval; otherwise, an interval with the same span
as the target that ends at S3DB's estimated content end is returned. (This "end of content"
value is estimated by `DataFeatures.last_observation` based upon the `sim_now` provided, using
S3DB metadata for the `DataFeature` in question.)

See also: [`DynamicOffset`](@ref)
"""
struct LatestOffset <: ScalarOffset end

# singleton instance
const latest = LatestOffset()

Base.show(io::IO, ::LatestOffset) = print(io, "LatestOffset()")
Base.print(io::IO, ::LatestOffset) = print(io, "latest")

struct DynamicOffset <: ScalarOffset
    fallback::Period
    match::Function

    function DynamicOffset(fallback, match)
        fallback < zero(fallback) || throw(ArgumentError("fallback must be negative"))
        return new(fallback, match)
    end
end

Base.broadcastable(a::DynamicOffset) = Ref(a)
Base.broadcastable(a::LatestOffset) = Ref(a)

"""
    DynamicOffset(; fallback=Day(-1), match=t -> true) -> DynamicOffset

Constructs a `DynamicOffset`. When a `DynamicOffset` is applied to a target interval,
metadata associated with the appropriate `DataFeature` is checked to determine whether data
for that target is expected to be available (for the `sim_now` provided).

As with a `LatestOffset`, if data for the target are expected to be available, the target
interval is simply returned as the observation interval; otherwise, the value of `fallback`
is added to the target interval and the check is repeated. This process continues until we
have an observation interval for which data are expected to be available.

### Matching Hour of Day (or Week)

The most common use of `DynamicOffset` is to simultaneously ensure that we are requesting
data that we expect will be available while also ensuring that the observation interval
matches the hour of day (or hour of week) of the target interval. This is accomplished by
specifying an appropriate value for `fallback` (which defaults to `Day(1)`):

```julia
match_hourofday = DynamicOffset(; fallback=Dates.Day(-1))
match_hourofweek = DynamicOffset(; fallback=Dates.Week(-1))
```

### Arbitrary Matching

If a `match` function is provided, its return value is checked alongside the available date
when determining whether to return the observation interval or fall back. The observation
interval returned must both be ≤ the estimated end of available content on S3DB and return
`true` when passed into the `match` function:

```julia
match_hourofday_tuesday = DynamicOffset(; match=t -> Dates.dayofweek(last(t)) == Dates.Tuesday)
```

Note that if your `target` is of type `<: AbstractInterval` (e.g., `HourEnding`), that will
be the type of the value passed into the `match` function. If you are planning to use
standard date functions to interact with this value, you can convert it to a `TimeType` with
`first` or `last` (to obtain the start or endpoint of the interval, respectively).

See also: [`LatestOffset`](@ref)
"""
DynamicOffset(; fallback=Day(-1), match=always) = DynamicOffset(fallback, match)

function Base.show(io::IO, o::DynamicOffset)
    print(io, "DynamicOffset(fallback=")
    repr_period(io, o.fallback)
    print(io, ", match=")
    show(io, o.match)
    print(io, ')')
end

function Base.print(io::IO, o::DynamicOffset)
    print(io, "DynamicOffset(", o.fallback, ", ", o.match, ')')
end

"""
    CustomOffset(apply::Function) -> CustomOffset

Constructs a `CustomOffset` using the supplied `apply` function. The `apply` function should
take a `target::AbstractInterval`, `last_observation::ZonedDateTime`, and a
`sim_now::ZonedDateTime` (in that order) and return a single observation interval.

Whenever a `CustomOffset` is applied to a target interval, the `apply` function is called.

```julia
custom_offset = CustomOffset((td, ce, sn) -> min(HourEnding(sn), td) + Dates.Hour(1))
```
"""
struct CustomOffset <: ScalarOffset
    # Function should take (target, last_observation, sim_now) and return observation interval
    apply::Function
end

Base.broadcastable(a::CustomOffset) = Ref(a)

"""
    SimNowOffset() -> SimNowOffset

Constructs a `SimNowOffset`. When a `SimNowOffset` is applied to a target interval, it
will return `sim_now`.

See also: [`DynamicOffset`](@ref)
"""
struct SimNowOffset <: ScalarOffset end

Base.print(io::IO, ::SimNowOffset) = print(io, "sim_now")
Base.broadcastable(a::SimNowOffset) = Ref(a)

##### CompoundOffset #####

"""
    CompoundOffset(o::Vector{ScalarOffset}) -> CompoundOffset

Constructs a `CompoundOffset`. A `CompoundOffset` is a "chain" of `SourceOffset`s that are
all applied to a target interval in sequence to yield the observation interval. For example,
`CompoundOffset(LatestOffset(), StaticOffset(Dates.Hour(-1)))` would apply the
`LatestOffset` then subtract one hour from the result.

A `CompoundOffset` must contain at least one `SourceOffset`. If none are provided, it
defaults to `StaticOffset(Day(0))`.

For convenience, `CompoundOffset`s may also be constructed by adding `SourceOffset`s
together:

```julia
julia> LatestOffset() + StaticOffset(Dates.Hour(-1))
CompoundOffset(LatestOffset(), StaticOffset(-1 hour))
```

Note that because the order in which `SourceOffset`s are applied is relevant,
`LatestOffset() + StaticOffset(Dates.Hour(-1))` will be functionally distinct from
`StaticOffset(Dates.Hour(-1)) + LatestOffset()`.

`CompoundOffset`s may also be constructed by subtracting a `StaticOffset` from another
`SourceOffset`. This is equivalent to the example above:

```julia
julia> LatestOffset() - StaticOffset(Dates.Hour(1))
CompoundOffset(LatestOffset(), StaticOffset(-1 hour))
```

Note that subtraction is only available for `StaticOffset`s.
"""
@auto_hash_equals struct CompoundOffset <: SourceOffset
    offsets::Vector{ScalarOffset}

    function CompoundOffset(o::Vector{ScalarOffset})
        if length(o) > 1
            # Remove extraneous StaticOffsets of zero.
            filter!(x -> !isa(x, StaticOffset) || x.period != zero(x.period), o)
        end

        if isempty(o)
            # CompoundOffsets must contain at least one ScalarOffset.
            push!(o, StaticOffset(Day(0)))
        end

        return new(o)
    end
end

CompoundOffset(o::Vector{<:ScalarOffset}) = CompoundOffset(Vector{ScalarOffset}(o))

CompoundOffset(o::ScalarOffset...) = CompoundOffset(collect(o))

Base.convert(::Type{CompoundOffset}, o::ScalarOffset) = CompoundOffset(ScalarOffset[o])

Base.:+(x::ScalarOffset, y::ScalarOffset) = CompoundOffset(ScalarOffset[x, y])
Base.:+(x::CompoundOffset, y::ScalarOffset) = CompoundOffset(vcat(x.offsets, y))
Base.:+(x::ScalarOffset, y::CompoundOffset) = CompoundOffset(vcat(x, y.offsets))
Base.:+(x::CompoundOffset, y::CompoundOffset) = CompoundOffset(vcat(x.offsets, y.offsets))
Base.:-(x::ScalarOffset, y::StaticOffset) = CompoundOffset(ScalarOffset[x, -y])
Base.:-(x::CompoundOffset, y::StaticOffset) = CompoundOffset(vcat(x.offsets, -y))

# Note: computing `isless` for CompoundOffset properly is rather difficult due to strange
# combinations:
# * `LatestOffset() - Day(30) + LatestOffset()`
# * `StaticOffset(Day(1)) - Hour(1)` vs. `StaticOffset(Hour(-1)) + Day(1))`
#
# What we've done here is a simplistic comparison which should work fairly well for the
# typical usage.
function Base.isless(x::CompoundOffset, y::CompoundOffset)
    len = max(length(x.offsets), length(y.offsets))

    for i in 1:(len - 1)
        a = get(x.offsets, i, StaticOffset(Hour(0)))
        b = get(y.offsets, i, StaticOffset(Hour(0)))
        a == b || return false
    end

    a = get(x.offsets, len, StaticOffset(Hour(0)))
    b = get(y.offsets, len, StaticOffset(Hour(0)))
    return isless(a, b)
end

function Base.show(io::IO, o::CompoundOffset)
    print(io, "CompoundOffset(")
    join(io, (sprint(show, offset) for offset in o.offsets), ", ")
    print(io, ')')
end

function Base.print(io::IO, o::CompoundOffset)
    print(io, o.offsets[1])

    for offset in o.offsets[2:end]
        if offset isa StaticOffset
            period = offset.period
            if sign(Dates.value(period)) < 0
                print(io, " - ", abs(period))
                continue
            end
        end

        print(io, " + ", offset)
    end
end

function apply(offset::StaticOffset, target::TargetType, args...)
    return target + offset.period
end

# Only works for StaticOffsets, because they don't need latest/sim_now information.
Base.:+(offset::StaticOffset, target::TargetType) = apply(offset, target)
Base.:+(target::TargetType, offset::SourceOffset) = offset + target

# Required to resolve dispatch ambiguity.
Base.:+(target::AnchoredInterval, offset::SourceOffset) = offset + target
Base.:+(offset::StaticOffset, target::AnchoredInterval) = apply(offset, target)

function Base.:+(offset::SourceOffset, target::TargetType)
    throw(
        ArgumentError(
            "addition between targets and SourceOffsets is only supported for StaticOffsets"
        )
    )
end

function apply(::LatestOffset, target::TargetType, last_observation::ZonedDateTime, args...)
    return min(target, last_observation)
end

function apply(::LatestOffset, target::AnchoredInterval, last_observation::ZonedDateTime, args...)
    T = typeof(target)
    return min(target, T(last_observation))
end

function apply(::SimNowOffset, target::TargetType, last_observation, sim_now::NowType)::NowType
    return sim_now
end

function apply(::SimNowOffset, target::AnchoredInterval, last_observation, sim_now::NowType)
    T = typeof(target)
    return T(sim_now)
end

function apply(
    offset::DynamicOffset, target::TargetType, last_observation::ZonedDateTime, sim_now::NowType
)
    criteria = t -> t <= last_observation && offset.match(t)
    return toprev(criteria, target; step=offset.fallback, same=true)
end

function apply(
    offset::DynamicOffset,
    target::AnchoredInterval,
    last_observation::ZonedDateTime,
    sim_now::NowType,
)
    T = typeof(target)
    criteria = t -> t <= last_observation && offset.match(t)
    return T(toprev(criteria, last(target); step=offset.fallback, same=true))
end

function apply(
    offset::CustomOffset, target::TargetType, last_observation, sim_now::NowType
)
    if hasmethod(offset.apply, Tuple{typeof.((sim_now, target))...})
        Base.depwarn(string(
            "Using a custom apply function of `apply(sim_now, target)` is deprecated; ",
            "use `apply(target, last_observation, sim_now)` instead",
        ), :apply)
        offset.apply(sim_now, target)
    else
        offset.apply(target, last_observation, sim_now)
    end
end

function apply(
    offset::CompoundOffset, target::TargetType, last_observation::ZonedDateTime, sim_now::NowType
)
    apply_binary_op(dt, offset) = apply(offset, dt, last_observation, sim_now)
    return foldl(apply_binary_op, offset.offsets; init=target)
end

apply(offset::SourceOffset, target::Missing, args...) = missing

"""
    apply(offset::SourceOffset, target::Union{AbstractInterval, ZonedDateTime, LaxZonedDateTime}, last_observation::ZonedDateTime, sim_now::ZonedDateTime) -> ZonedDateTime

Applies `offset` to the `target`, returning the new observation date. Methods for some
subtypes of `SourceOffset` also use `last_observation` and `sim_now` in their calculations. If
the `offset` is a `CompoundOffset`, each of the `ScalarOffset`s is applied sequentially to
generate the final observation date.

If `offset` is a `StaticOffset`, you can use `offset + target` syntax, as neither
`last_observation` nor `sim_now` information is required.
"""
apply(::SourceOffset, ::NowType, ::ZonedDateTime, ::ZonedDateTime)

"""
    AnchoredOffset(offset::DateOffset, anchor_point::Symbol)

Applies `offset` using `anchor_point` as the estimated content end then rounds down to the nearest
`Hour`. The `anchor_point` can be `:sim_now`, `:last_observation` or `:target`.

Useful if you want to fallback from the sim_now rather than the last_observation when working with
DynamicOffsets.
"""
function AnchoredOffset(offset, anchor_point::Symbol)
    return CustomOffset() do target, content, sim_now
        # Extract the appropriate `last_observation`, but convert target or sim_now
        # to ZonedDateTime
        f = if anchor_point === :target
            convert(ZonedDateTime, isa(target, AnchoredInterval) ? anchor(target) : target)
        elseif anchor_point === :sim_now
            convert(ZonedDateTime, sim_now)
        elseif anchor_point === :content_end || anchor_point === :last_observation
            # :content_end is deprecated
            # No warning has been added because this function will be removed in the next few weeks
            content
        else
            throw(ArgumentError(
                "AnchoredOffset only support 3 anchors :target, :sim_now or :last_observation" *
                "Note: :content_end has been replaced with :last_observation but still works for the time being"
            ))
        end

        t = DateOffsets.apply(offset, target, f::ZonedDateTime, sim_now)
        T = typeof(t)

        x = if T <: AnchoredInterval
            T(floor(anchor(t), Hour))
        else
            convert(T, floor(t, Hour))
        end

        return x
    end
end

"""
    LATEST_OFFSET

Return the [`LatestOffset`](@ref) rounded down to the nearest `Hour` when applied.
"""
const LATEST_OFFSET = AnchoredOffset(LatestOffset(), :content_end)

# NOTE (initial): For the reasons behind this Offset, please see
# https://gitlab.invenia.ca/invenia/DateOffsets.jl/issues/11 and linked discussion.
"""
    SIM_NOW_OFFSET

Always returns the sim_now rounded down to the nearest `Hour` when applied.
See also [`SimNowOffset`](@ref).
"""
const SIM_NOW_OFFSET = AnchoredOffset(SimNowOffset(), :content_end)
