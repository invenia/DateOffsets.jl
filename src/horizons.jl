immutable Horizon{T<:Period} <: DateOffset
    coverage::Period
    step::T
    start_ceil::Period
    start_offset::Period
end

"""
    Horizon(; coverage=Day(1), step=Hour(1), start_ceil=Day(1), start_offset=Hour(0)) -> Horizon

Constructs a `Horizon`, which allows a `sim_now` to be translated into a series of target
dates. Calling `Horizon()` without specifying any optional arguments will construct a
`Horizon` that generates a target date for every hour of the next day.

`coverage` represents the stretch of time over which target dates will be generated.

`step` defines the resolution of (the intverval between) the values returned.

`start_ceil` specifies how `sim_now` will be rounded before applying other offsets. The
default value of `Day(1)` means that when the `Horizon` is applied to a `sim_now`, that
`sim_now` will be rounded forward to the start of the next day before any target dates are
generated. (Specifying `Hour(1)` would start with the next hour instead of the next day.)

`start_offset` allows the user to define an additional offset to be applied before target
dates are generated. If the user wanted target dates for the current day instead of the next
day, they might specify `start_offset=Day(-1)`; if the first target date should be HE7
instead of HE1, they might specify `start_offset=Hour(6)`.
"""
function Horizon(; coverage=Day(1), step=Hour(1), start_ceil=Day(1), start_offset=Hour(0))
    return Horizon(coverage, step, start_ceil, start_offset)
end

"""
    Horizon(r::StepRange, [start_ceil::Period]) -> Horizon

Constructs a `Horizon` using a `StepRange` of `Period`s, which allows a `sim_now` to be
translated into a series of target dates. Using this constructor allows for easier creation
of some `Horizon`s; for example, target dates for two through eight hours ahead could be
defined as `Horizon(Dates.Hour(2):Dates.Hour(8))`.

If `start_ceil` is not specified, it will default to the `StepRange`'s `step` attribute.
"""
function Horizon(r::StepRange, start_ceil)
    return Horizon(r.stop - r.start + r.step, r.step, start_ceil, r.start - r.step)
end

Horizon(r::StepRange) = Horizon(r.stop - r.start + r.step, r.step, r.step, r.start - r.step)

function Base.string{T}(h::Horizon{T})
    start_info = ""
    has_offset = h.start_offset != zero(h.start_offset)
    if h.start_ceil != Day(1) || has_offset
        start_info = ", start date rounded up to $(h.start_ceil)"
        if has_offset
            start_info *= " + $(h.start_offset)"
        end
    end
    # Displaying {$T} seems like cluttery overkill here, but I'll keep it for now. —Gem
    return "Horizon{$T}($(h.coverage) at $(h.step) resolution$start_info)"
end

Base.show(io::IO, h::Horizon) = print(io, string(h))

"""
    targets{P<:Period, T<:Union{ZonedDateTime, LaxZonedDateTime}}(horizon::Horizon{P}, sim_now::ZonedDateTime) -> StepRange{T, P}

Generates the appropriate target dates for a batch of forecasts, given a `horizon` and a
`sim_now`.

Since `sim_now` is time zone–aware, Daylight Saving Time will be properly accounted for:
no target dates will be produced for hours that don't exist in the time zone and hours that
are "duplicated" will appear twice (with each being zoned correctly).
"""
function targets{P<:Period, T<:LZDT}(horizon::Horizon{P}, sim_now::T)
    base = ceil(sim_now, horizon.start_ceil) + horizon.start_offset
    return (base + horizon.step):horizon.step:(base + horizon.coverage)
end
