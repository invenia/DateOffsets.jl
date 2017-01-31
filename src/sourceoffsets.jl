abstract SourceOffset <: Offset
abstract ScalarOffset <: SourceOffset

"""
    StaticOffset(period::Period) -> StaticOffset

Constructs a `StaticOffset`. When a `StaticOffset` is applied to a target date, the `period`
is simply added to the target date to create the observation date.
"""
immutable StaticOffset <: ScalarOffset
    period::Period
end

Base.string(o::StaticOffset) = "StaticOffset($(o.period))"
Base.show(io::IO, o::StaticOffset) = print(io, string(o))

"""
    LatestOffset() -> LatestOffset

Constructs a `LatestOffset`. When a `LatestOffset` is applied to a target date, metadata
associated with the appropriate `DataSource` is checked to determine whether that target
date is expected to be available (for the given `sim_now`); if the target date is available,
it is returned as the observation date; otherwise, the latest target date expected to be
available is returned.
"""
immutable LatestOffset <: ScalarOffset end

Base.string(o::LatestOffset) = "LatestOffset()"
Base.show(io::IO, o::LatestOffset) = print(io, string(o))

immutable DynamicOffset <: ScalarOffset
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
date is expected to be available (for the given `sim_now`); as with a `LatestOffset`, if the
target date is available, it is returned as the observation date; otherwise, the value of
`fallback` is added to the target date and the check is repeated.

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

Base.string(o::DynamicOffset) = "DynamicOffset($(o.fallback), $(o.match))"
Base.show(io::IO, o::DynamicOffset) = print(io, string(o))

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
immutable CustomOffset <: ScalarOffset
    apply::Function     # Should take (sim_now, observation) and return observation
end

Base.string(o::CustomOffset) = "CustomOffset($(o.apply))"
Base.show(io::IO, o::CustomOffset) = print(io, string(o))

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
"""
immutable CompoundOffset <: SourceOffset
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

CompoundOffset{T<:ScalarOffset}(o::Vector{T}) = CompoundOffset(Vector{ScalarOffset}(o))

CompoundOffset(o::ScalarOffset...) = CompoundOffset(o)

Base.convert(::Type{CompoundOffset}, o::ScalarOffset) = CompoundOffset(ScalarOffset[o])

Base.:+(x::ScalarOffset, y::ScalarOffset) = CompoundOffset(ScalarOffset[x, y])
Base.:+(x::CompoundOffset, y::ScalarOffset) = CompoundOffset(vcat(x.offsets, y))
Base.:+(x::ScalarOffset, y::CompoundOffset) = CompoundOffset(vcat(x, y.offsets))
Base.:+(x::CompoundOffset, y::CompoundOffset) = CompoundOffset(vcat(x.offsets, y.offsets))
if VERSION < v"0.6-"
    Base.:.+{T<:ScalarOffset}(x::ScalarOffset, y::Array{T}) = [x] .+ y
    Base.:.+{T<:ScalarOffset}(x::Array{T}, y::ScalarOffset) = x .+ [y]
end

function Base.string(o::CompoundOffset)
    return "CompoundOffset($(join([string(offset) for offset in o.offsets], ", ")))"
end

Base.show(io::IO, o::CompoundOffset) = print(io, string(o))

function apply(offset::StaticOffset, target_date::LZDT, args...)
    return target_date + offset.period
end

function apply(::LatestOffset, target_date::LZDT, latest::ZonedDateTime, args...)
    return min(target_date, latest)
end

function apply(
    offset::DynamicOffset, target_date::LZDT, latest::ZonedDateTime, sim_now::ZonedDateTime
)
    criteria = t -> t <= latest && offset.match(t)
    return toprev(criteria, target_date; step=offset.fallback, same=true)
end

function apply(
    offset::CustomOffset, target_date::LZDT, latest, sim_now::ZonedDateTime
)
    return offset.apply(sim_now, target_date)
end

function apply(
    offset::CompoundOffset, target_date::LZDT, latest::ZonedDateTime, sim_now::ZonedDateTime
)
    apply_binary_op(dt, offset) = apply(offset, dt, latest, sim_now)
    return foldl(apply_binary_op, target_date, offset.offsets)
end

function apply(offset::SourceOffset, target_date::Nullable{ZonedDateTime}, args...)
    return isnull(target_date) ? target_date : apply(offset, get(target_date), args...)
end

"""
    apply(offset::SourceOffset, target_date::Union{ZonedDateTime, LaxZonedDateTime}, latest::ZonedDateTime, sim_now::ZonedDateTime) -> ZonedDateTime

Applies `offset` to the `target_date`, returning the new observation date. Methods for some
subtypes of `SourceOffset` also use `latest` and `sim_now` in their calculations. If the
`offset` is a `CompoundOffset`, each of the `ScalarOffset`s is applied sequentially to
generate the final observation date.
"""
apply(::SourceOffset, ::LZDT, ::ZonedDateTime, ::ZonedDateTime)

function observation_matrix{S<:SourceOffset}(
    offsets::Vector{S}, horizon::Horizon, sim_now::LZDT, latest::ZonedDateTime
)
    dates = repmat(targets(horizon, sim_now), 1, length(offsets))
    for (i, offset) in enumerate(offsets)
        dates[:, i] = map(dt -> apply(offset, dt, latest, sim_now), dates[:, i])
    end

    return hcat(repmat([sim_now], size(dates, 1)), dates)
end

"""
    observations{S<:SourceOffset, T<:Union{ZonedDateTime, LaxZonedDateTime}}(offsets::Vector{S}, horizon::Horizon, sim_now::T, latest::ZonedDateTime) -> (Vector{T}, Matrix{T})

Generates forecast or training observation dates for a single `sim_now` and any number of
`offsets`. This is accomplished by using the `horizon` to generate target dates for the
`sim_now`, duplicating the target dates for each element in `offsets`, and applying each
offset to its corresponding column of target dates to produce the observation dates.

The return value is a tuple, the first element of which is vector of `sim_now`s (with one
element for each target date). The second element of the return tuple is a matrix that
corresponds row-wise to the vector, with a column for each element in the `offsets` vector.

## Example

If your call looked like this:

```julia
offsets = [LatestOffset(), StaticOffset(Day(1))]
horizon = Horizon(; coverage=Day(1), step=Hour(1))
s, o = observations(offsets, horizon, sim_now, latest)
```

`s` would have 24 elements (or maybe 23 or 25: one for each hour of the next day) and `o`
would be a 24x2 matrix. Each element of `s` would be equal to `sim_now`. The first column of
`o` would contain the target dates (generated using `sim_now` and `horizon`) with a
`LatestOffset` applied, while the second would contain those target dates with a
`StaticOffset` of one day applied.
"""
function observations{S<:SourceOffset, T<:LZDT}(
    offsets::Vector{S}, horizon::Horizon, sim_now::T, latest::ZonedDateTime
)
    matrix = observation_matrix(offsets, horizon, sim_now, latest)
    return (matrix[:, 1], matrix[:, 2:end])
end

"""
    observations{S<:SourceOffset, T<:Union{ZonedDateTime, LaxZonedDateTime}}(offsets::Vector{T}, horizon::Horizon, sim_now::Vector{T}, latest::Vector{ZonedDateTime}) -> (Vector{T}, Matrix{T})

Generates forecast or training observation dates for a series of `sim_now`s and any number
of `offsets`, in a similar manner to the method that takes a single `sim_now`.

## Example

If your call looked like this:

```julia
offsets = [LatestOffset(), StaticOffset(Day(1))]
horizon = Horizon(; coverage=Day(1), step=Hour(1))
sim_nows = [now(TimeZone("America/Winnipeg"))] .- [Day(2), Day(1), Day(0)]
s, o = observations(offsets, horizon, sim_now, latest)
```

`s` would have 72 elements (±1: one for each hour of each of the three days) and `o` would
be a 72x2 matrix. Each element of `s` would be equal to one of the three `sim_now`s. The
first column of `o` would contain the target dates (generated using the `sim_now`s and
`horizon`) with a `LatestOffset` applied, while the second would contain those target dates
with a `StaticOffset` of one day applied.
"""
function observations{S<:SourceOffset, T<:LZDT}(
    offsets::Vector{S}, horizon::Horizon, sim_now::Vector{T}, latest::Vector{ZonedDateTime}
)
    matrix = vcat(
        map((sn, lt) -> observation_matrix(offsets, horizon, sn, lt), sim_now, latest)...
    )
    return (matrix[:, 1], matrix[:, 2:end])
end


#=
# TODO some of the tests for the version that calculates the latest target will go in the
# DataFeatures module.

# TODO put this information elsewhere

# TODO Keep this information around for now because it contains useful comments on dealing
# with ambiguous/missing datetimes and nullables.

# ----- DATA FEATURE OFFSETS -----
function static_offset{N<:NZDT, P<:Period}(
    dates::AbstractArray{N}, offsets::AbstractArray{P}
)
    # When landing on ambiguous dates, negative offsets will use :first and positive
    # offsets will use :last (both will use the value nearest to the base date). Must cast
    # dates as NullableArray to allow it to return null on "spring forward".

    return NullableArray{ZonedDateTime}(
        reshape(
            broadcast(
                (a, b) -> +(a, b, b < Millisecond(0) ? :last : :first),
                NullableArray(dates[:]),
                reshape(offsets, 1, length(offsets))
            ),
            (size(dates, 1), size(dates, 2) * length(offsets))
        )
    )
end

function static_offset{P<:Period}(
    dates::AbstractArray{LaxZonedDateTime}, offsets::AbstractArray{P}
)
    return reshape(
        dates[:] .+ reshape(offsets, 1, length(offsets)), 
        (size(dates, 1), size(dates, 2) * length(offsets))
    )
end

"""
    static_offset(dates::AbstractArray{ZonedDateTime}, offsets::Period...) -> NullableArray{ZonedDateTime}

Provides static (arithmetic) offsets from the base input (observation) `dates` provided. If
multiple `offsets` are specified, the set of input dates is duplicated columnwise for each
offset such that each offset can be applied to the original set of dates in its entirety.

The `offsets` can also be passed in as a single `AbstractArray{P}` where `P <: Period`;
`dates` may be a vector or a 2-dimensional array, but `offsets` will be treated as a vector.

The `dates` are returned in a `NullableArray` to allow for the possibility that some may be
(or become) invalid due to time zone transitions.
"""
function static_offset{N<:NZDT}(dates::AbstractArray{N}, offsets::Period...)
    return static_offset(dates, Period[o for o in offsets])
end

function static_offset(dates::AbstractArray{LaxZonedDateTime}, offsets::Period...)
    return static_offset(dates, Period[o for o in offsets])
end

"""
    latest_offset(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table) -> Array{ZonedDateTime}

Provides the target dates of the most recent available data in the table.

Here, "most recent available" is defined as the latest input data target date less than or
equal to the (observation) `date` provided that is expected to have an `availability_date`
(based on table metadata) less than or equal to the corresponding `sim_now`.

Operates row-wise on the `AbstractArray`s of `dates` and `sim_now`, expecting one `sim_now`
element for each row in `dates`; `table` should be an instance of type `Table`.

The dates are returned in a `NullableArray`.
"""
function recent_offset{N<:NZDT}(
    dates::AbstractArray{N}, sim_now::AbstractArray{ZonedDateTime}, table::Table
)
    return broadcast(
        min, NullableArray(dates), NullableArray(@mock latest_target(table, sim_now));
        lift=true
    )
end

# TODO: shouldn't import table information at all anymore; just take the latest target date as a ZDT

function dynamic_offset(
    date::LaxZonedDateTime, latest_target_date::ZonedDateTime, step::Period;
    match::Function=t -> true,
)
    step < zero(step) || throw(ArgumentError("step must be negative"))

    criteria = t -> t <= latest_target_date && match(t)
    return toprev(criteria, date; step=step, same=true)
end

"""
    dynamic_offset(date::ZonedDateTime, latest_target_date::ZonedDateTime, step::Period; match::Function=t -> true, ambiguous::Symbol=:last) -> ZonedDateTime

Provides the target dates of the most recent available data in the table, such that the
result conforms to the following rules:

* The result is equal to or precedes the `latest_target_date`
* The result is equal to or precedes the observation `date` by zero or more `step`s
* The `match` function returns true given the result

Operates row-wise on the `AbstractArray`s of `dates` and `sim_now`, expecting one `sim_now`
element for each row in `dates`; `step` is a `Period` that should be divisble by the
resolution of the data in the table; `table` should be an instance of type `Table`; `match`
should be a `DateFunction` that takes a single `ZonedDateTime` and returns `true` when that
value matches the desired criteria.

For example, if you wanted to exclude data from holidays, and you had a `holiday` function
that takes a `ZonedDateTime` and returns `true` if it's a holiday, you might pass
`match=x -> !holiday(x)`.

Modifying the `step` can easily accomplish complex offsets like same hour of day (`Day(-1)`)
or hour of week (`Week(-1)`).
"""
function dynamic_offset{P<:Period}(
    date::ZonedDateTime, latest_target_date::ZonedDateTime, step::P;
    match::Function=t -> true, ambiguous=:last
)
    step < P(0) || throw(ArgumentError("step must be negative"))

    # Use LaxZonedDateTime to avoid issues with landing on non-existent or ambiguous dates.
    lzdt = LaxZonedDateTime(date)

    criteria = t -> t <= latest_target_date && match(t) && !isnonexistent(t)
    lzdt = toprev(criteria, lzdt; step=step, same=true)

    return ZonedDateTime(lzdt, ambiguous)
end
=#
