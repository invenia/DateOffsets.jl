typealias NZDT Union{ZonedDateTime, Nullable{ZonedDateTime}}

abstract Offset

immutable Horizon <: Offset
    coverage::Period
    step::Period
    start_ceil::Period
    start_offset::Period
end

# "Static" horizons (e.g., 2 to 8 hours ahead, 0 to 75 minutes ahead)
Horizon(r::StepRange, ceil_start) = Horizon(r.stop - r.start + r.step, r.step, ceil_to, r.start - r.step)
Horizon(r::StepRange) = Horizon(r.stop - r.start + r.step, r.step, r.step, r.start - r.step)
# TODO: Test these, using the examples above.

# "Daily" horizons
function Horizon(; coverage=Day(1), step=Hour(1), start_ceil=Day(1), start_offset=Hour(0))
    return Horizon(coverage, step, start_ceil, start_offset)
end
# TODO: Test this

abstract SourceOffset <: Offset

immutable StaticOffset <: SourceOffset
    offset::Period
end

immutable LatestOffset <: SourceOffset end

immutable DynamicOffset <: SourceOffset
    fallback::Period
    match::Function

    function DynamicOffset(fallback, match)
        fallback < zero(fallback) || throw(ArgumentError("fallback must be negative"))
        return new(fallback, match)
    end
end

DynamicOffset(; fallback=Day(-1), match=t -> true) = DynamicOffset(fallback, match)

# TODO docstring
immutable CustomOffset <: SourceOffset
    apply::Function     # Should take (sim_now, observation) and return observation
end

# TODO add docstring info for hourofday and hourofweek
#
# Eric Davies [12:25]  
# Yeah. I like having people learn `DynamicOffset(Week(-1))` as then they can compose it. `DynamicOffsetHourOfWeek()` doesn't give them any tools for the future.
#
# Curtis Vogt [12:26]  
# Maybe we want to have a section in the docstring which mentions equivalent examples in MATLAB?

function show(io::IO, horizon::Horizon)
    start_info = ""
    has_offset = horizon.start_offset != zero(horizon.start_offset)
    if horizon.start_ceil != Day(1) || has_offset
        start_info = ", start date rounded up to $(horizon.start_ceil)"
        if has_offset
            start_info *= "with an offset of $(horizon.start_offset)"
        end
    end
    print(io, "Horizon($(horizon.coverage) at $(horizon.step) resolution$start_info)")
end
