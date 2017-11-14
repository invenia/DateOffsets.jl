abstract type SourceOffset <: DateOffset end
abstract type ScalarOffset <: SourceOffset end

"""
    StaticOffset(period::Period) -> StaticOffset

Constructs a `StaticOffset`. When a `StaticOffset` is applied to a target date, the `period`
is simply added to the target date to create the observation date.
"""
struct StaticOffset <: ScalarOffset
    period::Period
end

Base.isless(a::StaticOffset, b::StaticOffset) = isless(a.period, b.period)
Base.:-(a::StaticOffset) = (StaticOffset(-a.period))

Base.show(io::IO, o::StaticOffset) = print(io, "StaticOffset($(o.period))")

"""
    LatestOffset() -> LatestOffset

Constructs a `LatestOffset`. When a `LatestOffset` is applied to a target date, metadata
associated with the appropriate `DataSource` is checked to determine whether that target
date is expected to be available (for the given `sim_now`).

If the target date is available, that date is returned as the observation date; otherwise,
the latest target date expected to be available (based on table metadata) is returned.
"""
struct LatestOffset <: ScalarOffset end

Base.show(io::IO, o::LatestOffset) = print(io, "LatestOffset()")

struct DynamicOffset <: ScalarOffset
    fallback::Period
    match::Function

    function DynamicOffset(fallback, match)
        fallback < zero(fallback) || throw(ArgumentError("fallback must be negative"))
        return new(fallback, match)
    end
end

"""
    DynamicOffset(; fallback=Day(-1), match=t -> true) -> DynamicOffset

Constructs a `DynamicOffset`. When a `DynamicOffset` is applied to a target date, metadata
associated with the appropriate `DataSource` is checked to determine whether that target
date is expected to be available (for the given `sim_now`).

As with a `LatestOffset`, if the target date is available, it is returned as the observation
date; otherwise, the value of `fallback` is added to the target date and the check is
repeated. This process continues until the observation date passes the expected availability
check.

The most common use of `DynamicOffset` is to simultaneously ensure that the observation date
is available while also matching the hour of day (or hour of week) of the target date. This
is accomplished by specifying an appropriate `fallback`:

```julia
match_hourofday = DynamicOffset(; fallback=Dates.Day(-1))
match_hourofweek = DynamicOffset(; fallback=Dates.Week(-1))
```

If a `match` date function is provided, its return value is checked alongside the available
date when determining whether to return the target date or fall back. The observation date
returned must both be ≤ the latest available target date and return true when passed into
the `match` function.

Example:

```julia
match_hourofday_tuesday = DynamicOffset(; match=t -> Dates.dayofweek(t) == Dates.Tuesday)
```
"""
DynamicOffset(; fallback=Day(-1), match=t -> true) = DynamicOffset(fallback, match)

Base.show(io::IO, o::DynamicOffset) = print(io, "DynamicOffset($(o.fallback), $(o.match))")

"""
    CustomOffset(apply::Function) -> CustomOffset

Constructs a `CustomOffset` using the supplied `apply` function. The `apply` function should
take a `sim_now` and a `target_date` (in that order) and return a single observation date.
Whenever a `CustomOffset` is applied to a target date, the `apply` funcion is called.

Example:

```julia
custom_offset = CustomOffset((sn, td) -> min(ceil(sn, Dates.Day), td) + Dates.Hour(1))
```
"""
struct CustomOffset <: ScalarOffset
    apply::Function     # Should take (sim_now, observation) and return observation
end

Base.show(io::IO, o::CustomOffset) = print(io, "CustomOffset($(o.apply))")

##### CompoundOffset #####

"""
    CompoundOffset(o::Vector{ScalarOffset}) -> CompoundOffset

Constructs a `CompoundOffset`. A `CompoundOffset` is a "chain" of `SourceOffset`s that are
all applied to a target date in sequence to yield the observation date. For example,
`CompoundOffset([LatestOffset(), StaticOffset(Dates.Hour(-1))])` would apply the
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
struct CompoundOffset <: SourceOffset
    offsets::Vector{ScalarOffset}

    function CompoundOffset(o::Vector{ScalarOffset})
        if isempty(o)
            # CompoundOffsets must contain at least one ScalarOffset.
            push!(o, StaticOffset(Day(0)))
        elseif length(o) > 1
            # Remove extraneous StaticOffsets of zero.
            filter!(x -> !isa(x, StaticOffset) || x.period != zero(x.period), o)
        end
        return new(o)
    end
end

CompoundOffset(o::Vector{<:ScalarOffset}) = CompoundOffset(Vector{ScalarOffset}(o))

CompoundOffset(o::ScalarOffset...) = CompoundOffset(o)

Base.convert(::Type{CompoundOffset}, o::ScalarOffset) = CompoundOffset(ScalarOffset[o])

Base.:(==)(x::CompoundOffset, y::CompoundOffset) = x.offsets == y.offsets
Base.:+(x::ScalarOffset, y::ScalarOffset) = CompoundOffset(ScalarOffset[x, y])
Base.:+(x::CompoundOffset, y::ScalarOffset) = CompoundOffset(vcat(x.offsets, y))
Base.:+(x::ScalarOffset, y::CompoundOffset) = CompoundOffset(vcat(x, y.offsets))
Base.:+(x::CompoundOffset, y::CompoundOffset) = CompoundOffset(vcat(x.offsets, y.offsets))
Base.:-(x::ScalarOffset, y::StaticOffset) = CompoundOffset(ScalarOffset[x, -y])
Base.:-(x::CompoundOffset, y::StaticOffset) = CompoundOffset(vcat(x.offsets, -y))

function Base.show(io::IO, o::CompoundOffset)
    return print(
        io, "CompoundOffset($(join([string(offset) for offset in o.offsets], ", ")))"
    )
end

function apply(offset::StaticOffset, target_date::LZDT, args...)
    return target_date + offset.period
end

# Only works for StaticOffsets, because they don't need latest/sim_now information.
Base.:+(offset::StaticOffset, target_date::LZDT) = apply(offset, target_date)
Base.:+(target_date::LZDT, offset::SourceOffset) = offset + target_date
function Base.:+(offset::SourceOffset, target_date::LZDT)
    throw(
        ArgumentError(
            "addition between ZonedDateTimes and SourceOffsets is only supported for " *
            "StaticOffsets"
        )
    )
end

function apply(::LatestOffset, target_date::LZDT, latest::ZonedDateTime, args...)
    return min(target_date, latest)
end

function apply(
    offset::DynamicOffset, target_date::LZDT, latest::ZonedDateTime, sim_now::LZDT
)
    criteria = t -> t <= latest && offset.match(t)
    return toprev(criteria, target_date; step=offset.fallback, same=true)
end

function apply(
    offset::CustomOffset, target_date::LZDT, latest, sim_now::LZDT
)
    return offset.apply(sim_now, target_date)
end

function apply(
    offset::CompoundOffset, target_date::LZDT, latest::ZonedDateTime, sim_now::LZDT
)
    apply_binary_op(dt, offset) = apply(offset, dt, latest, sim_now)
    return foldl(apply_binary_op, target_date, offset.offsets)
end

function apply(offset::SourceOffset, target_date::Nullable{ZonedDateTime}, args...)
    return isnull(target_date)?target_date:Nullable(apply(offset,get(target_date),args...))
end

"""
    apply(offset::SourceOffset, target_date::Union{ZonedDateTime, LaxZonedDateTime}, latest::ZonedDateTime, sim_now::ZonedDateTime) -> ZonedDateTime

Applies `offset` to the `target_date`, returning the new observation date. Methods for some
subtypes of `SourceOffset` also use `latest` and `sim_now` in their calculations. If the
`offset` is a `CompoundOffset`, each of the `ScalarOffset`s is applied sequentially to
generate the final observation date.

If `offset` is a `StaticOffset`, you can use `offset + target_date` syntax, as neither
`latest` nor `sim_now` information is required.
"""
apply(::SourceOffset, ::LZDT, ::ZonedDateTime, ::ZonedDateTime)
