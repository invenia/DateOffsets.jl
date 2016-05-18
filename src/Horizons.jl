module Horizons

using Base.Dates
import Base: .+, +, .-, -

using TimeZones

utc = TimeZone("UTC")



#=
Generator functions in Julia:

    function producer()
        produce("start")
        for n=1:4
            produce(2n)
        end
        produce("stop")
    end

    t(args) = @task producer(args)

To consume:

    println(consume(t))

Or:

    for i in t
        println(t)
    end

A `Task` constructor requires a zero-argument function. In order for a producer to be
parameterized, you'll need to create an anonymous function or use the `@task` macro:

    task = Task(() -> producer(args))

Or:

    task = @task producer(args)
=#


#=
NOTE: The tasks/generators for horizons could be replaced by simple `StepRange`s, now that
that Gem got those working for `ZonedDateTime`s, but `StepRange`s are too simplistic to work
for the dynamic data offsets (offsets that can be defined like, "most recent data available
for the same hour of week as the target"). The plan is currently to use taks for everything,
but this is still kind of up in the air right now. (Another possibility would be to separate
horizons and static/dynamic data offsets again, but as Gem and Curt discussed it seems like
a good idea to couple these two concepts.)
=#


# TODO: Should we support non-range iterables (like lists) for horizons and source_offsets?


# HORIZON FUNCTIONS
# These are the topmost things that people will use.
# A horizon function takes a `TimeType` and a set of other criteria and returns a `Task`.
# Whenever `consume` is called on the `Task` (typically via a foreach loop) a `DateTime` is
# returned, representing a target date (not an offset).

# TODO: Clean up docstrings.

"""
Basic horizons. Probably not used in practice.
"""
function horizon(
    sim_now::TimeType, range::Range; include::Function=x->true, exclude::Function=x->false
)
    @task horizon_producer(sim_now + range; include=include, exclude=exclude)
end

horizon(sim_now::Function, range::Range; kwargs...) = horizon(sim_now(), range; kwargs...)

"""
Hourly horizons. Takes sim_now and rounds it to the start of the next hour.
"""

function horizon_hourly(
    sim_now::TimeType, range::Range; include::Function=x->true, exclude::Function=x->false
)
    start = trunc(sim_now + Hour(1) - Millisecond(1), Hour)
    horizon(start, range; include=include, exclude=exclude)
end

function horizon_hourly(sim_now::Function, range::Range; kwargs...)
    horizon_hourly(sim_now(), range; kwargs...)
end

horizon_hourly(range::Range; kwargs...) = horizon_hourly(now(utc), range; kwargs...)

"""
Horizons for each hour (or whatever) of a day (or whatever). See the example in the README.
"""
function horizon_next_day(
    sim_now::TimeType, resolution::Period=Hour(1),
    days_ahead::Period=Day(1), days_covered::Period=Day(1);
    include::Function=x->true, exclude::Function=x->false
)
    start = trunc(sim_now, Day) + days_ahead + resolution
    finish = trunc(sim_now, Day) + days_ahead + days_covered

    @task horizon_producer(start:resolution:finish; include=include, exclude=exclude)
end

function horizon_next_day(
    sim_now::Function, resolution::Period=Hour(1),
    days_ahead::Period=Day(1), days_covered::Period=Day(1); kwargs...
)
    horizon_next_day(sim_now(), resolution, days_ahead, days_covered; kwargs...)
end

function horizon_next_day(
    resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1);
    kwargs...
)
    horizon_next_day(now(utc), resolution, days_ahead, days_covered; kwargs...)
end


# TODO: Test all horizon functions for normal dates, spring forward, fall back (both on due
# date and target date).





# TODO: Probably need to support multiple types of iterable (not just ranges). Maybe?
# The ..._producers do.



# SOURCE OFFSET FUNCTIONS
# These are also top-level, but are specialized versions of horizons designed for static
# and dynamic offsets for input data.

# Basically for these, we'll pass in a series of target_dates (and a virtual now) and for
# each they should generate a corresponding data source date (and more?) based on the
# appropriate rules.

"""
Basic. Just passes back the target_dates, ignoring any that do/don't match
inclusion/exclusion criteria.
"""
function target_offset(
    sim_now::TimeType, target_date::Range; match::Function=x->true, shift::Period=Hour(0)
)
    @task offset_producer(sim_now, target_date; match=match, shift=shift)
end

function target_offset(sim_now::Function, target_date::Range; kwargs...)
    target_offset(sim_now(), target_date; kwargs...)
end

function target_offset(target_date::Range; kwargs...)
    target_offset(now(utc), target_date; kwargs...)
end


# Do we need include/exclude functions themselves?



# TODO: Assuming that we want the signature to be the same, but maybe we don't, so we could
# just pass in an integer (number to generate) instead.
# TODO: This function is potentially problemmatic if there is a long delay in actuals
# appearing in the DB? Perhaps in our data fetching code we want to just have a way of
# ignoring the target_date and querying the DB (or whatever) for the most recent data <
# sim_now.
function current_offset(
    sim_now::TimeType, target_date::Range;
    resolution::Period=Hour(1), match::Function=x->true, shift::Period=Hour(0)
)
# TODO: Once date rounding is implemented, this will work:
#    target_date = repmat([floor(sim_now, resolution)], length(target_date))
# Until then, we can round to hour, minute, etc., but not to a multiple of any resolution.
    target_date = repmat([trunc(sim_now, typeof(resolution))], length(target_date))
    @task offset_producer(sim_now, target_date; match=match, shift=shift)
end

function current_offset(sim_now::Function, target_date::Range; kwargs...)
    current_offset(sim_now(), target_date; kwargs...)
end

function current_offset(target_date::Range; kwargs...)
    current_offset(now(utc), target_date; kwargs...)
end

# Example: most recent actuals for same hour of day
#current_offset(sim_now, target_date; match=match_hourofday)

# Example: most recent actuals for twelve hours before same hour of day
#current_offset(sim_now, target_date; match=match_hourofday, shift=-Hour(12))

# Example: most recent actuals for one hour after same hour of week
#current_offset(sim_now, target_date; match=match_hourofweek, shift=Hour(1))

# TODO: TEST ALL OF THESE!




"""
For each element in a range, return a target date. The kwargs `include` and `exclude` are
`DateFunction`s; if supplied, they indicate which elements should be included (default: all)
and/or excluded (default: none). This may be helpful when creating dynamic offsets for data
source functions, for example.
"""
function horizon_producer(range::Range; match::Function=x->true, shift::Period=Hour(0))
    for d in recur(match, range + shift)
        produce(d)
    end
end

"""
Version for non-Range iterables.
"""
function horizon_producer(iterable; match::Function=x->true, shift::Period=Hour(0))
    for d in iterable + shift
        if match(d)
            produce(d)
        end
    end
end

# TODO: Test. This.





# TODO
# Okay, one proposal for a big rewrite:
# First, apply match (dynamic offset) if applicable
# Second, apply shift
#
# BUUUUUUUT.....
# Do we even need exclusion/inclusion criteria? I say rewrite it without.
# Do we need match for target_offsets in addition to current_offsets?

Call it match_target
Add available_shift kwarg which indicates how long after sim_now something is available
(or how long before the target? But what about forecast data with overlapping horizons?
No, it's just for actuals)





"""
Like the horizon_producer, but also spits back the available_date that we need to worry
about.
"""
function target_offset_producer(
    sim_now::TimeType, target_date::Range; match::Function=x->true, shift::Period=Hour(0)
)
    # TODO: Match does something a little different than current_offset. Call it include instead?
    for d in recur(match, target_date)
        produce((d + shift, sim_now))
    end
end

"""
Version for non-Range iterables.
"""
function target_offset_producer(
    sim_now::TimeType, target_date; match::Function=x->true, shift::Period=Hour(0)
)
    for d in target_date
        # TODO: Match does something a little different than below. Call it include instead?
        if match(d)
            produce((d + shift, sim_now))
        end
    end
end

# TODO: Test. This.

function current_offset_producer(
    sim_now::TimeType, target_date; match::Function=x->true, shift::Period=Hour(0)
)
    # TODO: Will this be for the right minute/second/etc.?
    for d in target_date
        # Matches some criteria between target_date and sim_now; bases offsets on sim_now.
        produce((toprev(match(d), sim_now) + shift, sim_now))
    end
end

# TODO: Test. This.

# TODO: Remove all include/exclude functions in favour of a single match function.



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
.+{T<:Period}(x::Union{TimeType, Period}, r::Range{T}) = (x + first(r)):step(r):(x + last(r))
.+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(x::Union{TimeType, Period}, r::Range{T}) = x .+ r
.-{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = (first(r) - x):step(r):(last(r) - x)
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






#=
Previous version of what is now `horizon_next_day`. We're doing this differently. (But I'm
keeping this code here in case it's useful later, or we change our minds again.)

"All horizons for a single day. Note that the input is of type `Date`, not `DateTime`."
function single_day(
    d::Date, step::Period=Hour(1);
    include::Function=x->true, exclude::Function=x->false
)
    @task horizon_producer(DateTime(d):step:DateTime(d + Day(1)) - Second(1), include, exclude)
end
=#

export horizon, horizon_hourly, horizon_next_day, source_offset

end
