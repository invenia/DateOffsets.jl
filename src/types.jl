typealias NZDT Union{ZonedDateTime, Nullable{ZonedDateTime}}

abstract Offset

immutable Horizon <: Offset
    coverage::Period
    step::Period
    ceil_to::Period
    start_offset::Period
end

# "Static" horizons (e.g., 2 to 8 hours ahead, 0 to 75 minutes ahead)
Horizon(r::StepRange, ceil_to) = Horizon(r.stop - r.start + r.step, r.step, ceil_to, r.start - r.step)
Horizon(r::StepRange) = Horizon(r.stop - r.start + r.step, r.step, r.step, r.start - r.step)
# TODO: Test these, using the examples above.

# "Daily" horizons
Horizon(coverage::Period, step, ceil_to) = Horizon(coverage, step, ceil_to, Day(0))
Horizon(coverage::Period, step) = Horizon(coverage, step, Day(1), Day(0))
Horizon(coverage::Period) = Horizon(coverage, Hour(1), Day(1), Day(0))
Horizon() = Horizon(Day(1))
# TODO: Test these.

abstract SourceOffset <: Offset

immutable StaticOffset <: SourceOffset
    offset::Period
end

immutable RecentOffset <: SourceOffset end

immutable DynamicOffset <: SourceOffset
    step::Period
    match::Function

    function DynamicOffset(step, match)
        step < zero(step) || throw(ArgumentError("step must be negative"))
        return new(step, match, check_availability)
    end
end

DynamicOffset(step) = DynamicOffset(step, t -> true)

# TODO add docstring info for hourofday and hourofweek
#
# Eric Davies [12:25]  
# Yeah. I like having people learn `DynamicOffset(Week(-1))` as then they can compose it. `DynamicOffsetHourOfWeek()` doesn't give them any tools for the future.
#
# Curtis Vogt [12:26]  
# Maybe we want to have a section in the docstring which mentions equivalent examples in MATLAB?
