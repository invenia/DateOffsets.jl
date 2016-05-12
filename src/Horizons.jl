module Horizons

using Base.Dates
import Base: .+, +, .-, -


# We'll want basic horizon constructors for:
#   X:(Z):Y hours
#   every [hour, minute, ...] in a [day, week, ...]


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


# HORIZON FUNCTIONS
# These are the topmost things that people will use.
# A horizon function takes a `TimeType` and a set of other criteria and returns a `Task`.
# Whenever `consume` is called on the `Task` (typically via a foreach loop) a `DateTime` is
# returned, representing a target date (not an offset).

"""
Basic horizons.
"""
function horizon(
    due_date::TimeType, range::Range;
    include::Function=x->true, exclude::Function=x->false
)
    @task horizon_producer(due_date + range; include=include, exclude=exclude)
end

"""
Horizons for each hour (or whatever) of a day (or whatever). (Uh, clean that up and name
properly.) See the example in the README.
"""
function horizon_next_day(
    due_date::TimeType, resolution::Period=Hour(1),
    days_ahead::Period=Day(1), days_covered::Period=Day(1);
    include::Function=x->true, exclude::Function=x->false
)
    start = trunc(due_date, Day) + days_ahead + resolution
    finish = trunc(due_date, Day) + days_ahead + days_covered
    @task horizon_producer(start:resolution:finish; include=include, exclude=exclude)
end

# TODO: Test all horizon functions for normal dates, spring forward, fall back (both on due
# date and target date).





# DATA SOURCE FUNCTIONS
# These are also top-level, but are specialized versions of horizons designed for static
# and dynamic offsets.

# TODO: Prototype and write data source tasks.

# TODO: Because these will take available dates into account, they will need to know what
# `now` is. Support passing in a value for `now` (or a function?); defaults to `Base.now()`.



"""
For each element in a range, return a target date. The kwargs `include` and `exclude` are
`DateFunction`s; if supplied, they indicate which elements should be included (default: all)
and/or excluded (default: none). This may be helpful when creating dynamic offsets for data
source functions, for example.
"""
function horizon_producer(
    range::Range; include::Function=x->true, exclude::Function=x->false
)
    # Combine include and exclude functions into a single include function.
    master_include = x -> include(x) && ~exclude(x)

    for d in recur(master_include, range)
        produce(d)
    end
end

# TODO: Test. This.




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

export horizon, horizon_next_day

end
