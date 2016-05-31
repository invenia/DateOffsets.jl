module Horizons

using Base.Dates
import Base: .+, +, .-, -, start, next, done, length, eltype

using TimeZones

utc = TimeZone("UTC")



"""
Hourly horizons. Takes sim_now and rounds it to the start of the next hour.
Typically period_iterable will be a range, but a list will also work.
"""
function horizon_hourly(sim_now::TimeType, period_iterable)
    start = trunc(sim_now + Hour(1) - Millisecond(1), Hour)
    return start + period_iterable
end

function horizon_hourly(sim_now::Function, period_iterable)
    horizon_hourly(sim_now(), period_iterable)
end

horizon_hourly(period_iterable) = horizon_hourly(now(utc), period_iterable)

"""
Horizons for each hour (or whatever) of a day (or whatever). See the example in the README.
"""
function horizon_next_day(
    sim_now::TimeType=now(utc);
    resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1)
)
    start = trunc(sim_now, Day) + days_ahead + resolution
    finish = trunc(sim_now, Day) + days_ahead + days_covered
    return start:resolution:finish
end

function horizon_next_day(
    sim_now::Function;
    resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1)
)
    horizon_next_day(sim_now(), resolution, days_ahead, days_covered)
end


# TODO: Rename one of the match functions. One is a factory for date functions and the other
# is a date function itself.
# Add explanation for date functions and factories.

typealias Limit Union{TimeType, Period}

# Source Offsets
# Iterable; each element is a tuple containing the target date and the associated Fallback.
immutable SourceOffsets{T<:TimeType, L<:Limit}
    target_dates::AbstractArray{T}        # Forecast target dates.
    base::Nullable{T}
    match::Function
    resolution::Period
    limit::Nullable{L}
end

# Convert non-nullable args to nullables.
function SourceOffsets{T<:TimeType, L<:Limit}(
    target_dates::AbstractArray{T},
    base::T,
    match::Function,
    resolution::Period,
    limit::L
)
    return SourceOffsets(target_dates, Nullable(base), match, resolution, Nullable(limit))
end

# Support for keyword args.
function SourceOffsets{T<:TimeType}(
    target_dates::AbstractArray{T};
    base=Nullable{TimeType}(),
    match::Function=x -> y -> true,
    resolution::Period=Hour(1),
    limit=Nullable{TimeType}()
)
    return SourceOffsets(target_dates, base, match, resolution, limit)
end

start(::SourceOffsets) = 1

function next(iter::SourceOffsets, state)
    args = [
        get(iter.base, iter.target_dates[state]),
        iter.match(iter.target_dates[state]),
        iter.resolution
    ]

    if !isnull(iter.limit)
        push!(args, get(iter.limit))
    end

    return ((iter.target_dates[state], Fallback(args...)), state + 1)
end

done(iter::SourceOffsets, state) = state > length(iter.target_dates)

eltype{T}(::Type{SourceOffsets{T}}) = Tuple{T, T}

length(iter::SourceOffsets) = length(iter.target_dates)


immutable Fallback
    base::TimeType
    match::Function
    resolution::Period
    limit::TimeType

    function Fallback(
        base::TimeType, match::Function, resolution::Period, limit::TimeType
    )
        # TODO: Once date rounding is implemented, this will work:
        # base = floor(base, resolution)
        # Until then we can round to hour, min, etc but not to a multiple of any resolution.
        base = trunc(base, typeof(resolution))
        new(base, match, resolution, limit)
    end
end

# TODO: Does the resolution need to be stored after the initial rounding?

# Handle the case where the limit is provided as a Period instead of a TimeType.
function Fallback(base::TimeType, match::Function, resolution::Period, limit::Period)
    return Fallback(base, match, resolution, base - limit)
end

# The default value for limit essentially boils down to "only return one thing".
function Fallback(
    base::TimeType,
    match::Function,
    resolution::Period,
)
    # TODO: Once date rounding is implemented, this will work:
    # return Fallback(base, match, resolution, floor(base, resolution))
    # Until then we can round to hour, minute, etc. but not to a multiple of any resolution.
    return Fallback(base, match, resolution, trunc(base, typeof(resolution)))
end

# Allow using kwargs for optional parameters.
function Fallback(
    base::TimeType;
    match::Function=x -> true,
    resolution::Period=Hour(1),
    # TODO: Once date rounding is implemented, this will work:
    # limit::Union{TimeType, Period}=floor(base, resolution)
    # Until then we can round to hour, minute, etc. but not to a multiple of any resolution.
    limit::Union{TimeType, Period}=trunc(base, typeof(resolution))
)
    return Fallback(base, match, resolution, limit)
end

start(iter::Fallback) = iter.base

function next(iter::Fallback, state)
    return (state, toprev(iter.match, state; step=-iter.resolution))
end

done(iter::Fallback, state) = state < iter.limit

eltype(::Type{Fallback}) = TimeType

# TODO: OH DEAR GOD TEST ALL OF THIS WITH EVERY TYPE OF LIMIT


# DATE FUNCTIONS
# These will be used by the data source functions to e.g. match hour of day or hour of week.

#=
A `DateFunction` is an "inclusion" funtion used by adjusters that takes a single `TimeType`
and returns true when it matches certain criteria. When we're trying to match hour of day or
hour of week the criterion we're trying to match (the HOD or HOW of another date) is itself
variable, which complicates things. For this reason these functions are `DateFunction`
factories: they take a single target `TimeType` (the date we're trying to match) and return
a lambda function which is the `DateFunction` we'll use for inclusion.
=#

"`DateFunction` factory. Takes a target hour of day and returns a `DateFunction` to match."
match_hourofday(target::TimeType) = d -> hour(d) == hour(target)
match_hourofday(target::Integer) = d -> hour(d) == target

"`DateFunction` factory. Takes a target hour of week and returns a `DateFunction` to match."
match_hourofweek(target::TimeType) = d -> hourofweek(d) == hourofweek(target)
match_hourofweek(target::Integer) = d -> hourofweek(d) == target


# UTILITY FUNCTIONS
# Generic utility functions required by Horizons.jl (but not necessarily specific to it).
# Should probably go in Curt's DateUtils.jl repo.

"""
Returns an integer indicating the hour of week (0 through 167). For locales in which weeks
can have more or fewer than 168 hours (those that observe DST), two consecutive hours may
return the same result (or an integer may be skipped, as the case may be). This was judged
preferable to having a potential 169th hour for our use case.
"""
hourofweek(d::TimeType) = (dayofweek(d) - 1) * 24 + hour(d)


# Allows arithmetic between a `DateTime`/`ZonedDateTime`/`Period` and a range of `Period`s.
.+{T<:Period}(x::Union{TimeType,Period}, r::Range{T}) = (x + first(r)):step(r):(x + last(r))
.+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(x::Union{TimeType, Period}, r::Range{T}) = x .+ r
.-{T<:Period}(r::Range{T}, x::Union{TimeType,Period}) = (first(r) - x):step(r):(last(r) - x)
-{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = r .- x


# Math between a single `Period` and a range of `DateTime`/`ZonedDateTime`s already works.
# Stolen from usr/local/Cellar/julia/0.4.1/share/julia/base/dates/ranges.jl:

#=
.+{T<:TimeType}(x::Period, r::Range{T}) = (x+first(r)):step(r):(x+last(r))
.+{T<:TimeType}(r::Range{T},x::Period) = x .+ r
+{T<:TimeType}(r::Range{T},x::Period) = x .+ r
+{T<:TimeType}(x::Period,r::Range{T}) = x .+ r
.-{T<:TimeType}(r::Range{T},x::Period) = (first(r)-x):step(r):(last(r)-x)
-{T<:TimeType}(r::Range{T},x::Period) = r .- x
=#

export horizon_hourly,
       horizon_next_day,
       SourceOffsets,
       Fallback,
       match_hourofday,
       match_hourofweek

end
