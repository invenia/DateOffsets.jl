function observation_matrix(
    offsets::Vector{<:SourceOffset},
    horizon::Horizon,
    sim_now::NowType,
    content_end::ZonedDateTime,
)
    t = targets(horizon, sim_now)
    o = repmat(t, 1, length(offsets))
    for (i, offset) in enumerate(offsets)
        o[:, i] = map(dt -> apply(offset, dt, content_end, sim_now), o[:, i])
    end

    # I'd prefer to use this fill dispatch, but it has type issues on 32-bit systems:
    # return hcat(fill(sim_now, (length(t),)), t, o)
    # https://github.com/JuliaLang/julia/issues/20855
    return hcat(fill(sim_now, length(t)), t, o)
end

"""
    observations(offsets::Vector{<:SourceOffset}, horizon::Horizon, sim_now::T, content_end::ZonedDateTime) where T<:Union{ZonedDateTime, LaxZonedDateTime} -> (Vector{T}, Vector{T}, Matrix{T})

Generates forecast or training observation intervals for a single `sim_now` and any number
of `offsets`. This is accomplished by using the `horizon` to generate target intervals for
the `sim_now`, duplicating the targets for each element in `offsets`, and applying each
offset to its corresponding column of targets to produce the observation intervals.

The return value is a tuple, the first element of which is vector of `sim_now`s, the
second is a vector of target intervals, and the third is the matrix of observation
intervals. The vectors of `sim_now`s and targets are the same size (the `sim_now` that is
passed in is duplicated) and correspond row-wise to the matrix of observation intervals
(which will have one column for each element in the `offsets` vector).

## Example

If your call looks like this:

```julia
offsets = [LatestOffset(), StaticOffset(Day(1))]
horizon = Horizon{HourEnding}(; span=Day(1))
s, t, o = observations(offsets, horizon, sim_now, content_end)
```

`s` and `t` would each have 24 elements (or maybe 23 or 25: one for each hour of the next
day) and `o` would be a 24x2 matrix. Each element of `s` would be equal to `sim_now`, and
the elements of `t` would be the target intervals returned by the call
`targets(horizon, sim_now)`. The first column of `o` would contain the values of `t` with
`LatestOffset` applied, while the second would contain the values of `t` with a
`StaticOffset` of one day applied.
"""
function observations(
    offsets::Vector{<:SourceOffset},
    horizon::Horizon,
    sim_now::NowType,
    content_end::ZonedDateTime,
)
    matrix = observation_matrix(offsets, horizon, sim_now, content_end)
    return (matrix[:, 1], matrix[:, 2], matrix[:, 3:end])
end

"""
    observations(offsets::Vector{<:SourceOffset}, horizon::Horizon, sim_now::Vector{T}, content_end::Vector{ZonedDateTime}) where T<:Union{ZonedDateTime, LaxZonedDateTime} -> (Vector{T}, Vector{T}, Matrix{T})

Generates forecast or training observation intervals for a series of `sim_now`s and any
number of `offsets`, in a similar manner to the method that takes a single `sim_now`.

The return value is a tuple, the first element of which is vector of `sim_now`s, the
second is a vector of target intervals, and the third is the matrix of observation
intervals. The vectors of `sim_now`s and targets are the same size (the `sim_now` that is
passed in is duplicated) and correspond row-wise to the matrix of observation intervals
(which will have one column for each element in the `offsets` vector).

## Example

If your call looked like this:

```julia
offsets = [LatestOffset(), StaticOffset(Day(1))]
horizon = Horizon{HourEnding}(; span=Day(1))
sim_nows = [now(tz"America/Winnipeg")] .- [Day(2), Day(1), Day(0)]
s, t, o = observations(offsets, horizon, sim_now, content_end)
```

`s` and `t` would each have 24 elements (±1: one for each hour of each of the three day
period) and `o` would be a 72x2 matrix. Each element of `s` would be equal to one of the
three `sim_now`s, and the elements of `t` would be the target intervals returned by calling
`targets(horizon, sim_now)` for each `sim_now`. The first column of `o` would contain the
values of `t` with `LatestOffset` applied, while the second would contain the values of `t`
with a `StaticOffset` of one day applied.
"""
function observations(
    offsets::Vector{<:SourceOffset},
    horizon::Horizon,
    sim_now::Vector{<:NowType},
    content_end::Vector{ZonedDateTime},
)
    matrix = vcat(
        map((sn, lt) -> observation_matrix(offsets, horizon, sn, lt), sim_now, content_end)...
    )
    return (matrix[:, 1], matrix[:, 2], matrix[:, 3:end])
end
