struct Horizon <: DateOffset
    step::Period
    span::Period
    start_ceil::Period
    start_offset::Period
end

"""
    Horizon(; step=Hour(1), span=Day(1), start_ceil=Day(1), start_offset=Hour(0)) -> Horizon

Constructs a `Horizon`, which allows a `sim_now` to be translated into a series of
`AnchoredInterval`s representing forecast targets.

`step` specifies the duration of the `AnchoredInterval` targets that will be generated. If
no `step` is specified, the targets will be of type `HourEnding` by default.

`start_ceil` specifies how `sim_now` will be rounded before applying `start_offset`. The
default value of `Day(1)` means that when the `Horizon` is applied to a `sim_now`, that
`sim_now` will be rounded forward to the start of the next day before any targets are
generated. (Specifying `Hour(1)` would start with the next hour instead of the next day.)

`start_offset` allows the user to define an additional offset to be applied before targets
are generated. If the user wanted targets for the current day instead of the next day, they
might specify `start_offset=Day(-1)`; if the first target date should be HE7 instead of HE1,
they might specify `start_offset=Hour(6)`.
"""
function Horizon(;
    step=Hour(1),
    span=Day(1),
    start_ceil=Day(1),
    start_offset=Hour(0),
    coverage=nothing,
)
    if coverage !== nothing
        Base.depwarn(
            "Horizon(; coverage=Day(1), ...) is deprecated, use " *
            "Horizon(; span=Day(1), ...) instead.",
            :Horizon
        )
        span = coverage
    end

    return Horizon(step, span, start_ceil, start_offset)
end

#= POST-DEPRECATION VERSION OF THIS FUNCTION:
function Horizon(; step=Hour(1), span=Day(1), start_ceil=Day(1), start_offset=Hour(0))
    return Horizon(step, span, start_ceil, start_offset)
end
=#

##### v0.3 DEPRECATION ####
function Horizon(r::StepRange, start_ceil)
    Base.depwarn(
        "Horizon(r::StepRange, start_ceil)) is deprecated, use " *
        "Horizon(step(r), last(r) - first(r) + step(r), start_ceil, first(r) - step(r)) " *
        "instead. Horizons aren't exactly like ranges; if you try to use them that way " *
        "you're probably going to have a bad time. Sorry.",
        :Horizon,
    )
    return Horizon(
        step(r), last(r) - first(r) + step(r), start_ceil, first(r) - step(r)
    )
end

function Horizon(r::StepRange)
    Base.depwarn(
        "Horizon(r::StepRange)) is deprecated, use " *
        "Horizon(step(r), last(r) - first(r) + step(r), step(r), first(r) - step(r)) " *
        "instead. Horizons aren't exactly like ranges; if you try to use them that way " *
        "you're probably going to have a bad time. Sorry.",
        :Horizon,
    )
    return Horizon(
        step(r), last(r) - first(r) + step(r), step(r), first(r) - step(r)
    )
end
##### END v0.3 DEPRECATION ####

function Base.print(io::IO, h::Horizon)
    # Print to io in order to keep properties like :limit and :compact
    if get(io, :compact, false)
        io = IOContext(io, :limit=>true)
    end

    start_info = ""
    has_offset = h.start_offset != zero(h.start_offset)
    if h.start_ceil != Day(1) || has_offset
        start_info = ", start date rounded up to $(h.start_ceil)"
        if has_offset
            start_info *= " + $(h.start_offset)"
        end
    end
    print(io, "Horizon($(h.span) at $(h.step) resolution$start_info)")
end

function Base.show(io::IO, h::Horizon)
    print(io, "Horizon($(h.step), $(h.span), $(h.start_ceil), $(h.start_offset))")
end

"""
    targets(horizon::Horizon, sim_now::Union{ZonedDateTime, LaxZonedDateTime}) -> StepRange

Generates the appropriate target intervals for a batch of forecasts, given a `horizon` and a
`sim_now`.

Since `sim_now` is time zone–aware, Daylight Saving Time will be properly accounted for:
no target dates will be produced for hours that don't exist in the time zone and hours that
are "duplicated" will appear twice (with each being zoned correctly).
"""
function targets(horizon::Horizon, sim_now::NowType)
    base = ceil(sim_now, horizon.start_ceil) + horizon.start_offset
    T = AnchoredInterval{-horizon.step}
    return T(base + horizon.step):horizon.step:T(base + horizon.span)
end
