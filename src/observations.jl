function observation_matrix{S<:SourceOffset}(
    offsets::Vector{S}, horizon::Horizon, sim_now::LZDT, latest::ZonedDateTime
)
    dates = repmat(targets(horizon, sim_now), 1, length(offsets))
    for (i, offset) in enumerate(offsets)
        dates[:, i] = map(dt -> apply(offset, dt, latest, sim_now), dates[:, i])
    end

    return hcat(repmat([sim_now], size(dates, 1)), dates)
end


# TODO update code and documentation to reflect target_date indices as well

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

The return value is a tuple, the first element of which is vector of `sim_now`s (with one
element for each target date). The second element of the return tuple is a matrix that
corresponds row-wise to the vector, with a column for each element in the `offsets` vector.

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
