abstract type SourceOffset <: DateOffset end
abstract type ScalarOffset <: SourceOffset end

"""
    StaticOffset(period::Period) -> StaticOffset

Constructs a `StaticOffset`. When a `StaticOffset` is applied to a target interval, the
`period` is simply added to the target to create the observation interval.
"""
struct StaticOffset <: ScalarOffset
    period::Period

    # Avoid a stack overflow issue with `StaticOffset(0)`
    @static if VERSION < v"0.7"
        StaticOffset(p::Period) = new(p)
    end
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

if VERSION >= v"0.7"
    Base.broadcastable(a::StaticOffset) = Ref(a)
end
"""
    LatestOffset() -> LatestOffset

Constructs a `LatestOffset`. When a `LatestOffset` is applied to a target interval, metadata
associated with the appropriate `DataFeature` is checked to determine whether that data for
that target is expected to be available (for the `sim_now` provided).

If data for the target is expected to be available on S3DB at `sim_now`, that target
interval is returned as the observation interval; otherwise, an interval with the same span
as the target that ends at S3DB's estimated content end is returned. (This "end of content"
value is estimated by `DataFeatures.content_end` based upon the `sim_now` provided, using
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

if VERSION >= v"0.7"
    Base.broadcastable(a::LatestOffset) = Ref(a)
end

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
take a `target::AbstractInterval`, `content_end::ZonedDateTime`, and a
`sim_now::ZonedDateTime` (in that order) and return a single observation interval.

Whenever a `CustomOffset` is applied to a target interval, the `apply` funcion is called.

```julia
custom_offset = CustomOffset((td, ce, sn) -> min(HourEnding(sn), td) + Dates.Hour(1))
```
"""
struct CustomOffset <: ScalarOffset
    # Function should take (target, content_end, sim_now) and return observation interval
    apply::Function
end

"""
    SimNowOffset() -> SimNowOffset

Constructs a `SimNowOffset`. When a `SimNowOffset` is applied to a target interval, it
will return `sim_now`.

See also: [`DynamicOffset`](@ref)
"""
struct SimNowOffset <: ScalarOffset end

Base.print(io::IO, ::SimNowOffset) = print(io, "sim_now")

if VERSION >= v"0.7"
    Base.broadcastable(a::SimNowOffset) = Ref(a)
end

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

if VERSION < v"0.7-"
    Base.show(io::IO, ::Type{SimNowOffset}) = print(io, "SimNowOffset")
    Base.show(io::IO, ::Type{LatestOffset}) = print(io, "LatestOffset")
    Base.show(io::IO, ::Type{StaticOffset}) = print(io, "StaticOffset")
    Base.show(io::IO, ::Type{DynamicOffset}) = print(io, "DynamicOffset")
    Base.show(io::IO, ::Type{CustomOffset}) = print(io, "CustomOffset")
    Base.show(io::IO, ::Type{CompoundOffset}) = print(io, "CompoundOffset")
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

function apply(::LatestOffset, target::TargetType, content_end::ZonedDateTime, args...)
    return min(target, content_end)
end

function apply(::LatestOffset, target::T, content_end::ZonedDateTime, args...) where
        T <: AnchoredInterval
    return min(target, T(content_end, inclusivity(target)))
end

function apply(::SimNowOffset, target::TargetType, content_end, sim_now::NowType)::NowType
    return sim_now
end

function apply(::SimNowOffset, target::T, content_end, sim_now::NowType) where
        T <: AnchoredInterval
    return T(sim_now, inclusivity(target))
end

function apply(
    offset::DynamicOffset, target::TargetType, content_end::ZonedDateTime, sim_now::NowType
)
    criteria = t -> t <= content_end && offset.match(t)
    return toprev(criteria, target; step=offset.fallback, same=true)
end

function apply(
    offset::DynamicOffset, target::T, content_end::ZonedDateTime, sim_now::NowType
) where T <: AnchoredInterval
    criteria = t -> t <= content_end && offset.match(t)
    return T(toprev(criteria, last(target); step=offset.fallback, same=true))
end

function apply(
    offset::CustomOffset, target::TargetType, content_end, sim_now::NowType
)
    if hasmethod(offset.apply, Tuple{typeof.((sim_now, target))...})
        Base.depwarn(string(
            "Using a custom apply function of `apply(sim_now, target)` is deprecated; ",
            "use `apply(target, content_end, sim_now)` instead",
        ), :apply)
        offset.apply(sim_now, target)
    else
        offset.apply(target, content_end, sim_now)
    end
end

function apply(
    offset::CompoundOffset, target::TargetType, content_end::ZonedDateTime, sim_now::NowType
)
    apply_binary_op(dt, offset) = apply(offset, dt, content_end, sim_now)
    if VERSION < v"0.7"
        return foldl(apply_binary_op, target, offset.offsets)
    else
        return foldl(apply_binary_op, offset.offsets; init=target)
    end
end

apply(offset::SourceOffset, target::Missing, args...) = missing

"""
    apply(offset::SourceOffset, target::Union{AbstractInterval, ZonedDateTime, LaxZonedDateTime}, content_end::ZonedDateTime, sim_now::ZonedDateTime) -> ZonedDateTime

Applies `offset` to the `target`, returning the new observation date. Methods for some
subtypes of `SourceOffset` also use `content_end` and `sim_now` in their calculations. If
the `offset` is a `CompoundOffset`, each of the `ScalarOffset`s is applied sequentially to
generate the final observation date.

If `offset` is a `StaticOffset`, you can use `offset + target` syntax, as neither
`content_end` nor `sim_now` information is required.
"""
apply(::SourceOffset, ::NowType, ::ZonedDateTime, ::ZonedDateTime)

#=
Specific types of `CustomOffset`s used in Simulation.jl

- The LATEST_OFFSET and SIM_NOW_OFFSET adds round to the nearest hour
- The AnchoredOffset allows you to specify whether you want to use the target, sim_now
  or computed content as the content end for the internal offset.
  Useful if you're want to fallback from the sim_now rather than the content end when work with
  DynamicOffsets
=#

# NOTE (2018-11-28): The initial version of this also wasn't correct because we want to
# define a DynamicOffset with a fallback that uses just uses sim_now as the content_end to
# avoid a :validity mismatch between rt and da.
# Related issue: https://gitlab.invenia.ca/invenia/Simulation.jl/issues/85
function AnchoredOffset(offset, a::Symbol)
    return CustomOffset() do target, content, sim_now
        # Extract the appropriate `content_end`, but convert target or sim_now
        # to ZonedDateTime
        f = if a === :target
            convert(ZonedDateTime, isa(target, AnchoredInterval) ? anchor(target) : target)
        elseif a === :sim_now
            convert(ZonedDateTime, sim_now)
        elseif a === :content_end
            content
        else
            throw(ArgumentError(
                "AnchoredOffset only support 3 anchors :target, :sim_now or :content_end"
            ))
        end

        t = DateOffsets.apply(offset, target, f::ZonedDateTime, sim_now)
        T = typeof(t)

        x = if isa(t, AnchoredInterval)
            T(floor(anchor(t), Hour), inclusivity(t))
        else
            convert(T, floor(t, Hour))
        end

        return x
    end
end

const LATEST_OFFSET = AnchoredOffset(LatestOffset(), :content_end)

# NOTE (initial): For the reasons behind this Offset, please see
# https://gitlab.invenia.ca/invenia/DateOffsets.jl/issues/11 and linked discussion.
const SIM_NOW_OFFSET = AnchoredOffset(SimNowOffset(), :content_end)
