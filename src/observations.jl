function observation_matrix{S<:SourceOffset}(
    offsets::Vector{S}, horizon::Horizon, sim_now::LZDT, latest::ZonedDateTime
)
    t = targets(horizon, sim_now)
    o = repmat(t, 1, length(offsets))
    for (i, offset) in enumerate(offsets)
        o[:, i] = map(dt -> apply(offset, dt, latest, sim_now), o[:, i])
    end

    return hcat(fill(sim_now, (length(t),)), t, o)
end


"""
    observations{S<:SourceOffset, T<:Union{ZonedDateTime, LaxZonedDateTime}}(offsets::Vector{S}, horizon::Horizon, sim_now::T, latest::ZonedDateTime) -> (Vector{T}, Vector{T}, Matrix{T})

Generates forecast or training observation dates for a single `sim_now` and any number of
`offsets`. This is accomplished by using the `horizon` to generate target dates for the
`sim_now`, duplicating the target dates for each element in `offsets`, and applying each
offset to its corresponding column of target dates to produce the observation dates.

The return value is a tuple, the first element of which is vector of `sim_now`s, the
second is a vector of `target_date`s, and the third is the matrix of observation dates.
The vectors of `sim_now`s and `target_date`s are the same size (the input `sim_now` is
duplicated) and correspond row-wise to the matrix of observation dates (which will have one
column for each element in the `offsets` vector).

## Example

If your call looked like this:

```julia
offsets = [LatestOffset(), StaticOffset(Day(1))]
horizon = Horizon(; coverage=Day(1), step=Hour(1))
s, t, o = observations(offsets, horizon, sim_now, latest)
```

`s` and `t` would each have 24 elements (or maybe 23 or 25: one for each hour of the next
day) and `o` would be a 24x2 matrix. Each element of `s` would be equal to `sim_now`, and
the elements of `t` would be the target dates returned by the call
`targets(horizon, sim_now)`. The first column of `o` would contain the values of `t` with
`LatestOffset` applied, while the second would contain the values of `t` with a
`StaticOffset` of one day applied.
"""
function observations{S<:SourceOffset, T<:LZDT}(
    offsets::Vector{S}, horizon::Horizon, sim_now::T, latest::ZonedDateTime
)
    matrix = observation_matrix(offsets, horizon, sim_now, latest)
    return (matrix[:, 1], matrix[:, 2], matrix[:, 3:end])
end

"""
    observations{S<:SourceOffset, T<:Union{ZonedDateTime, LaxZonedDateTime}}(offsets::Vector{T}, horizon::Horizon, sim_now::Vector{T}, latest::Vector{ZonedDateTime}) -> (Vector{T}, Vector{T}, Matrix{T})

Generates forecast or training observation dates for a series of `sim_now`s and any number
of `offsets`, in a similar manner to the method that takes a single `sim_now`.

The return value is a tuple, the first element of which is vector of `sim_now`s, the
second is a vector of `target_date`s, and the third is the matrix of observation dates.
The vectors of `sim_now`s and `target_date`s are the same size (the input `sim_now` is
duplicated) and correspond row-wise to the matrix of observation dates (which will have one
column for each element in the `offsets` vector).

## Example

If your call looked like this:

```julia
offsets = [LatestOffset(), StaticOffset(Day(1))]
horizon = Horizon(; coverage=Day(1), step=Hour(1))
sim_nows = [now(TimeZone("America/Winnipeg"))] .- [Day(2), Day(1), Day(0)]
s, t, o = observations(offsets, horizon, sim_now, latest)
```

`s` and `t` would each have 24 elements (±1: one for each hour of each of the three day) and
`o` would be a 72x2 matrix. Each element of `s` would be equal to one of the three
`sim_now`s, and the elements of `t` would be the target dates returned by calling
`targets(horizon, sim_now)` for each `sim_now`. The first column of `o` would contain the
values of `t` with `LatestOffset` applied, while the second would contain the values of `t`
with a `StaticOffset` of one day applied.
"""
function observations{S<:SourceOffset, T<:LZDT}(
    offsets::Vector{S}, horizon::Horizon, sim_now::Vector{T}, latest::Vector{ZonedDateTime}
)
    matrix = vcat(
        map((sn, lt) -> observation_matrix(offsets, horizon, sn, lt), sim_now, latest)...
    )
    return (matrix[:, 1], matrix[:, 2], matrix[:, 3:end])
end
