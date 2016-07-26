# ----- FORECAST HORIZONS -----

# TODO: Proper docstrings.

"""
Hourly horizons. Takes sim_now and rounds it to the start of the next hour.
"""
function horizon_hourly{P<:Period}(
    sim_now::ZonedDateTime, periods::AbstractArray{P}; ceil_to=Hour(1)
)
    return ceil(sim_now, ceil_to) + periods
end

function horizon_hourly{P<:Period}(periods::AbstractArray{P})
    horizon_hourly(now(TimeZone("UTC")), periods)
end

"""
Horizons for each hour (or whatever) of a day (or whatever). See the example in the README.
"""
function horizon_daily(
    sim_now::ZonedDateTime=now(TimeZone("UTC"));
    resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1),
    floor_to=Day(1)
)
    base = floor(sim_now, floor_to) + days_ahead
    return (base + days_ahead):resolution:(base + days_covered)
end


# ------- OBSERVATION DATES -------

# Takes a target date, the training window(s), and the sim_now, then returns all target
# dates/sim_nows

# Note: assumes that all markets are siloed and run idependently. If we had a situation in
# which another market's DST transition affects the time that this market runs (say, if all
# markets had to run at the same time), then this code might have to be more complex.

# After several attempts, this is the best design I was able to come up with. Let's talk
# about it!

# Note this potential problem: if it is run on a day where the target_dates include a DST
# transition, it will assume an incorrect relationship between sim_now and target_dates
# (and/or we will have an unusual number of targets for each observation). It is POSSIBLE
# that this is actually the behaviour that we want (so that the current model is trained up
# as though it were typical, even though it isn't). If we don't want this, the function
# could be redesigned to take a horizon function instead of an array of target_dates. This
# would allow it to call the function for each of our sim_nows, giving perfect results. We
# could even pass back the "real" forecast target_dates in our tuple, meaning that the user
# never needs to call the horizons function themselves.

function observation_dates{T<:TimeType, P<:Period}(
    target_dates::AbstractArray{T}, sim_now::TimeType, run_frequency::Period,
    training_window::Interval{P}...
)
    # Convert the training windows from offsets to ranges of dates.
    training_window = map(w -> sim_now - w, training_window)

    # Find all sim_nows that are within the training windows.
    earliest = minimum(map(minimum, training_window))

    # A DateFunction that returns true if the date is within any of the training windows.
    within_windows(dt) = any(window -> in(dt, window), training_window) || dt < earliest
    # Should simply be this:
    # within_windows(dt) = any(window -> in(dt, window), training_window)
    # Can be reverted once https://github.com/JuliaLang/julia/issues/17513 is fixed.

    # Generate all sim_nows that are within the training windows.
    sim_nows = flipdim(recur(within_windows, sim_now:-run_frequency:earliest), 1)

    # Determine the horizon offsets between target_dates and sim_now.
    offsets = target_dates - sim_now

    # Determine the observation target_dates for each sim_now.
    observations = static_offset(sim_nows, offsets)

    # Vectorize it (row-wise).
    observations = vec(Base.PermutedDimsArrays.PermutedDimsArray(observations, [2, 1]))

    # Expand sim_nows so that we have a sim_now for each observation row.
    sim_nows = repeat(sim_nows; inner=length(offsets))

    return (observations, sim_nows)
end

function observation_dates{T<:TimeType}(
    target_dates::AbstractArray{T}, sim_now::TimeType, run_frequency::Period,
    training_offset::Period
)
    return observation_dates(
        target_dates, sim_now, run_frequency,
        zero(typeof(training_offset)) .. training_offset
    )
end


# ----- DATE OFFSETS -----

"""
Provides static (arithmetic) offsets from the base input dates provided. If multiple offsets
are specified, the set of input dates is duplicated columnwise for each offset such that
each offset can be applied to the original set of dates in its entirety.

Dates can be 1- or 2-dimensional, but offsets will be treated as a vector.
"""
function static_offset{T<:TimeType, P<:Period}(
    dates::AbstractArray{T}, offsets::AbstractArray{P}
)
    return reshape(
        broadcast(+, vec(dates), reshape(offsets, 1, length(offsets))),
        (size(dates, 1), size(dates, 2) * length(offsets))
    )
end

function static_offset{T<:TimeType}(dates::AbstractArray{T}, offsets::Period...)
    return static_offset(dates, Period[o for o in offsets])
end

"""
Provides dates for the "most recent" data from at or before the target dates.
We just want the most recent data point that is less than or equal to the target.

For dynamic and recent offsets, we need a vector of sim_nows with length equal to the number
of rows in the dates array.
"""
function recent_offset{T<:TimeType}(
    dates::AbstractArray{T}, sim_now::AbstractArray{T}, table::Table
)
    return broadcast(min, dates, latest_target(table, sim_now))
end

# NOTE: step should be divisible by the data resolution (if you're doing a dynamic match function)
# The step provided here needs to be:
#    1. divisible by the resolution of the data you want to fetch
#    2. NEGATIVE
# So if this table has data at fifteen minute resolution, acceptable values for step would
# include Minute(-15), Minute(-30), and Hour(-1), but you wouldn't want to use Minute(-10)
# because then the algorithm might end up choosing a target date for which you don't have
# any data (if you chose Minute(-5) things would be okay, but it's a little less efficient).

#=
match is an (optional) `DateFunction`
for example, if you wanted to exclude data from holidays, and you had a `holiday` function that
takes a date and returns `true` if it's a holiday, you might pass `match=x -> !holiday(x)

A `DateFunction` is an "inclusion" funtion used by adjusters that takes a single `TimeType`
and returns true when it matches certain criteria. When we're trying to match hour of day or
hour of week the criterion we're trying to match (the HOD or HOW of another date) is itself
variable, which complicates things. For this reason these functions are `DateFunction`
factories: they take a single target `TimeType` (the date we're trying to match) and return
a lambda function which is the `DateFunction` we'll use for inclusion.
=#

# Can take a 2-dimensional dates array like static offsets.
function dynamic_offset{T<:TimeType}(
    dates::AbstractArray{T}, sim_now::AbstractArray{T}, step::Period, table::Table;
    match::Function=current -> true
)
    step > Millisecond(0) && throw(ArgumentError("step cannot be positive"))

    fall_back(date, latest) = toprev(
        current -> current <= latest && match(current), date; step=step, same=true
    )

    return broadcast(fall_back, dates, latest_target(table, sim_now))
end

# Note: hourofday and hourofweek have no underscores because they follow the pattern laid
# out by Dates.dayofweek

function dynamic_offset_hourofday{T<:TimeType}(
    dates::AbstractArray{T}, sim_now::AbstractArray{T}, table::Table
)
    return dynamic_offset(dates, sim_now, Day(-1), table)
end

function dynamic_offset_hourofweek{T<:TimeType}(
    dates::AbstractArray{T}, sim_now::AbstractArray{T}, table::Table
)
    return dynamic_offset(dates, sim_now, Week(-1), table)
end

# NOTE to Curtis: I think this meets our requirements, and provides sufficient
# building-blocks to meet future requirements (as it's pretty low-level).
# The "Support offsets from different reference points" requirement is met by virtue of the
# fact that you're passing in whatever dates you want to use yourself (so you can pass in
# the target dates if you want to use those or you could pass in some other dates).
