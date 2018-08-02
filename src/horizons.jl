struct Horizon <: DateOffset
    step::Period
    span::Period
    start_fn::Function
end

_start_fn(sim_now) = ceil(sim_now, Day)

"""
    Horizon(; step=Hour(1), span=Day(1), start_fn=sim_now -> ceil(sim_now, Day)) -> Horizon

Constructs a `Horizon`, which allows a `sim_now` to be translated into a series of
`AnchoredInterval`s representing forecast targets.

`step` specifies the duration of the `AnchoredInterval` targets that will be generated. If
no `step` is specified, the targets will be of type `HourEnding` by default.

`start_fn` specifies how `sim_now` should be modified (rounding, applying offsets, etc.)
before targets are generated. The default of `sim_now -> ceil(sim_now, Day)` indicates that
the `sim_now` supplied should be rounded up to the start of the next day. If, for example,
you wanted to generate targets for the day **after** tomorrow, you might do this:

```julia
horizon = Horizon(; start_fn=sim_now -> ceil(sim_now, Day) + Day(1))
```
"""
function Horizon(; step=Hour(1), span=Day(1), start_fn=_start_fn)
    return Horizon(step, span, start_fn)
end

function Base.:(==)(a::Horizon, b::Horizon)
    return a.step == b.step && a.span == b.span && a.start_fn == b.start_fn
end

function Base.print(io::IO, h::Horizon)
    # Print to io in order to keep properties like :limit and :compact
    if get(io, :compact, false)
        io = IOContext(io, :limit=>true)
    end

    start_txt = h.start_fn == _start_fn ? "" : ", start_fn: $(h.start_fn)"
    print(io, "Horizon($(h.span) at $(h.step) resolution$start_txt)")
end

function Base.show(io::IO, h::Horizon)
    print(io, "Horizon($(h.step), $(h.span), $(h.start_fn))")
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
    base = horizon.start_fn(sim_now)
    T = AnchoredInterval{-horizon.step}
    return T(base + horizon.step):horizon.step:T(base + horizon.span)
end
