# NullableArray is a subtype of AbstractArray, but NullableArray{ZonedDateTime} is not a
# subtype of AbstractArray{ZonedDateTime}. For functions that want either type of array with
# ZonedDateTime elements, we can use AbstractArray{N} where N<:NZDT.
typealias NZDT Union{ZonedDateTime, Nullable{ZonedDateTime}}

# ----- FORECAST HORIZONS -----

"""
    horizon_hourly{P<:Period}(sim_now::ZonedDateTime, periods::AbstractArray{P}; ceil_to::Period=Hour(1)) -> `StepRange{ZonedDateTime}`

Calculates the `target_date`s for a batch of forecasts defined by discrete set of
offsets (`periods`) from the current time (`sim_now`).

This is accomplished by rounding `sim_now` up to the nearest hour and adding the `periods`
the offsets to the result. The `ceil_to` keyword may be provided to specify that `sim_now`
should be rounded up to a value other than `Hour(1)` (e.g., `Minute(30)`).
"""
function horizon_hourly{P<:Period}(
    sim_now::ZonedDateTime, periods::AbstractArray{P}; ceil_to::Period=Hour(1)
)
    return ceil(sim_now, ceil_to) + periods
end

function horizon_hourly{P<:Period}(periods::AbstractArray{P})
    horizon_hourly(now(TimeZone("UTC")), periods)
end

"""
    horizon_daily(sim_now::ZonedDateTime=now(TimeZone("UTC")); resolution::Period=Hour(1), days_ahead::Period=Day(1), days_covered::Period=Day(1), floor_to::Period=Day(1)) -> StepRange{ZonedDateTime}

Calculates the `target_date`s for a batch of forecasts for a specific day.

This is accomplished by rounding `sim_now` to the beginning of the next day, then producing
`target_date`s for each hour of that day.

Since `sim_now` must be a `ZonedDateTime`, Daylight Saving Time will be properly accounted
for: no `target_date`s will be produced for hours that don't exist in the time zone and
hours that are "duplicated" will appear twice (with each being zoned correctly).

The `resolution` keyword argument sets the resolution of the values returned; `days_ahead`
controls the span between `sim_now` and the output; `days_covered` defines the total length
of time covered by the values returned; and `floor_to` specifies the period to which
`sim_now` is rounded prior to beginning.
"""
function horizon_daily(
    sim_now::ZonedDateTime=now(TimeZone("UTC")); resolution::Period=Hour(1),
    days_ahead::Period=Day(1), days_covered::Period=Day(1), floor_to::Period=Day(1)
)
    base = floor(sim_now, floor_to) + days_ahead
    return (base + resolution):resolution:(base + days_covered)
end


# ------- OBSERVATION DATES -------

"""
    observation_dates{P<:Period}(target_dates::AbstractArray{ZonedDateTime}, sim_now::ZonedDateTime, frequency::Period, training_window::Interval{P}...) -> (NullableArray{ZonedDateTime}, Array{ZonedDateTime})

Takes the collection of forecast `target_dates`, a single `sim_now`, the desired `frequency`
of observations, and one or more `training_window` intervals and returns as tuple of
observation `target_dates` and associated `sim_now`s. The vector of `sim_now`s will be
expanded such that it is the same length as the observation dates.

The `frequency` should be the frequency at which batches of forecasts are generated (e.g.,
`Dates.Day(1)`).

The `training_window` should be an `Interval` of `Period`s, indicating an offset from
`sim_now`. For example, `Dates.Month(0) .. Dates.Month(3)` would indicate that the training
set should include observations from three months ago up until the current time (`sim_now`).
Any number of `training_window`s may be provided. Instead of an `Interval`, you may indicate
the size of your `training_window` with a single `Period` (e.g., `Dates.Month(3)`).

The observation `target_dates` returned in the tuple is a `NullableArray`. This is the
result of an internal call to `static_offset`, and allow for the possibility that some of
the dates may be (or become) invalid due to time zone transitions; by contrast, `sim_now`
should never contain invalid values, so is not `Nullable`.
"""
function observation_dates{N<:NZDT, P<:Period}(
    target_dates::AbstractArray{N}, sim_now::ZonedDateTime, frequency::Period,
    training_offsets::Interval{P}...
)
    # Convert the training windows from offsets to ranges of dates.
    training_windows = map(w -> sim_now - w, training_offsets)

    # Find all sim_nows that are within the training windows.
    earliest = minimum(map(minimum, training_windows))

    # A DateFunction that returns true if the date is within any of the training windows.
    within_windows(dt) = any(window -> in(dt, window), training_windows)

    # Generate all sim_nows that are within the training windows.
    sim_nows = collect(sim_now:-frequency:earliest; non_existent=:skip, ambiguous=:last)
    sim_nows = flipdim(filter(within_windows, sim_nows), 1)

    # Determine the horizon offsets between target_dates and sim_now.
    offsets = target_dates .- sim_now
    # TODO: We may want to handle this by passing in the horizon function instead of
    # inferring the offset.

    # Determine the observation target_dates for each sim_now.
    observations = static_offset(LaxZonedDateTime.(sim_nows), offsets)

    # Vectorize it (row-wise).
    observations = vec(Base.PermutedDimsArrays.PermutedDimsArray(observations, [2, 1]))
    observations = lax2nullable(observations, :last)

    # Expand sim_nows so that we have a sim_now for each observation row.
    sim_nows = repeat(sim_nows; inner=length(offsets))

    return (observations, sim_nows)
end

function observation_dates{N<:NZDT}(
    target_dates::AbstractArray{N}, sim_now::ZonedDateTime, frequency::Period,
    training_offset::Period
)
    return observation_dates(
        target_dates, sim_now, frequency, zero(typeof(training_offset)) .. training_offset
    )
end


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
    recent_offset(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table) -> Array{ZonedDateTime}

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

function dynamic_offset{P<:Period}(
    date::LaxZonedDateTime, latest_target_date::ZonedDateTime, step::P;
    match::Function=t -> true,
)
    step < P(0) || throw(ArgumentError("step must be negative"))

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

function dynamic_offset(
    date::Nullable{ZonedDateTime}, latest_target_date::ZonedDateTime, step::Period;
    match::Function=t -> true
)
    isnull(date) && return date
    return Nullable(dynamic_offset(get(date), latest_target_date, step; match=match))
end

function dynamic_offset{N<:NZDT}(
    date::N, sim_now::ZonedDateTime, step::Period, table::Table;
    match::Function=current -> true
)
    latest_target_date = @mock latest_target(table, sim_now)
    return dynamic_offset(date, latest_target_date, step; match=match)
end

function dynamic_offset{N<:NZDT,P<:Period}(
    dates::AbstractArray{N}, sim_nows::AbstractArray{ZonedDateTime},
    step::P, table::Table; match::Function=current -> true
)
    # TODO: Square brackets only necessary in 0.5 to support dot syntax.
    return dynamic_offset.(dates, sim_nows, [step], [table]; match=match)
end

function dynamic_offset{P<:Period}(
    dates::NullableArray{ZonedDateTime}, sim_nows::AbstractArray{ZonedDateTime},
    step::P, table::Table; match::Function=current -> true
)
    # NullableArray in, NullableArray out.
    return NullableArray(dynamic_offset.(dates, sim_nows, [step], [table]; match=match))
end

"""
    dynamic_offset_hourofday(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table) -> NullableArray{ZonedDateTime}

Provides the target dates of the most recent available data in the table that have the same
hour of day (0–23) as the corresponding `dates` provided.

Here, "most recent available" is defined as the latest input data target date less than or
equal to the `date` provided that is expected to have an `availability_date` (based on table
metadata) less than or equal to the appropriate `sim_now`.

Operates row-wise on the `AbstractArray`s of `dates` and `sim_now`, expecting one `sim_now`
element for each row in `dates`; `table` should be an instance of type `Table`.

If a `NullableArray` of `dates` are passed in, the return type will also be `NullableArray`.
"""
function dynamic_offset_hourofday{N<:NZDT}(
    dates::AbstractArray{N}, sim_nows::AbstractArray{ZonedDateTime}, table::Table
)
    return dynamic_offset(dates, sim_nows, Day(-1), table)
end

"""
    dynamic_offset_hourofweek(dates::AbstractArray{ZonedDateTime}, sim_now::AbstractArray{ZonedDateTime}, table::Table) -> NullableArray{ZonedDateTime}

Provides the target dates of the most recent available data in the table that have the same
hour of week (0–167) as the corresponding `dates` provided.

Here, "most recent available" is defined as the latest input data target date less than or
equal to the `date` provided that is expected to have an `availability_date` (based on table
metadata) less than or equal to the appropriate `sim_now`.

Operates row-wise on the `AbstractArray`s of `dates` and `sim_now`, expecting one `sim_now`
element for each row in `dates`; `table` should be an instance of type `Table`.

If a `NullableArray` of `dates` are passed in, the return type will also be `NullableArray`.
"""
function dynamic_offset_hourofweek{N<:NZDT}(
    dates::AbstractArray{N}, sim_nows::AbstractArray{ZonedDateTime}, table::Table
)
    return dynamic_offset(dates, sim_nows, Week(-1), table)
end
