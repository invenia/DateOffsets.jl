abstract Offset

##### Horizon #####

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

function Base.string(h::Horizon)
    start_info = ""
    has_offset = h.start_offset != zero(h.start_offset)
    if h.start_ceil != Day(1) || has_offset
        start_info = ", start date rounded up to $(h.start_ceil)"
        if has_offset
            start_info *= "+ $(h.start_offset)"
        end
    end
    return "Horizon($(h.coverage) at $(h.step) resolution$start_info)"
end

Base.show(io::IO, h::Horizon) = print(io, string(h))

##### SourceOffset #####

abstract SourceOffset <: Offset
abstract ScalarOffset <: SourceOffset

immutable StaticOffset <: ScalarOffset
    period::Period
end

Base.string(o::StaticOffset) = "StaticOffset($(o.period))"
Base.show(io::IO, o::StaticOffset) = print(io, string(o))

immutable LatestOffset <: ScalarOffset end

Base.string(o::LatestOffset) = "LatestOffset()"
Base.show(io::IO, o::LatestOffset) = print(io, string(o))

immutable DynamicOffset <: ScalarOffset
    fallback::Period
    match::Function

    function DynamicOffset(fallback, match)
        fallback < zero(fallback) || throw(ArgumentError("fallback must be negative"))
        return new(fallback, match)
    end
end

DynamicOffset(; fallback=Day(-1), match=t -> true) = DynamicOffset(fallback, match)

Base.string(o::DynamicOffset) = "DynamicOffset($(o.fallback), $(o.match))"
Base.show(io::IO, o::DynamicOffset) = print(io, string(o))

# TODO add docstring info for hourofday and hourofweek
#
# Eric Davies [12:25]  
# Yeah. I like having people learn `DynamicOffset(Week(-1))` as then they can compose it. `DynamicOffsetHourOfWeek()` doesn't give them any tools for the future.
#
# Curtis Vogt [12:26]  
# Maybe we want to have a section in the docstring which mentions equivalent examples in MATLAB?

# TODO docstring
immutable CustomOffset <: ScalarOffset
    apply::Function     # Should take (sim_now, observation) and return observation
end

Base.string(o::CustomOffset) = "CustomOffset($(o.apply))"
Base.show(io::IO, o::CustomOffset) = print(io, string(o))

##### CompoundOffset #####

# TODO docstring
immutable CompoundOffset <: SourceOffset
    offsets::Vector{ScalarOffset}

    function CompoundOffset(o::Vector{ScalarOffset})
        if isempty(o)
            # CompoundOffsets must contain at least one ScalarOffset.
            push!(o, StaticOffset(Day(0)))
        elseif length(o) > 1
            # Remove extraneous StaticOffsets of zero.
            filter!(x -> !isa(x, StaticOffset) || x.period != zero(x.period), o)
        end
        return new(o)
    end
end

CompoundOffset{T<:ScalarOffset}(o::Vector{T}) = CompoundOffset(Vector{ScalarOffset}(o))

CompoundOffset(o::ScalarOffset...) = CompoundOffset(o)

Base.convert(::Type{CompoundOffset}, o::ScalarOffset) = CompoundOffset(ScalarOffset[o])

Base.:+(x::ScalarOffset, y::ScalarOffset) = CompoundOffset(ScalarOffset[x, y])
Base.:+(x::CompoundOffset, y::ScalarOffset) = CompoundOffset(vcat(x.offsets, y))
Base.:+(x::ScalarOffset, y::CompoundOffset) = CompoundOffset(vcat(x, y.offsets))
Base.:+(x::CompoundOffset, y::CompoundOffset) = CompoundOffset(vcat(x.offsets, y.offsets))
# TODO TEST THESE
Base.:.+{T<:ScalarOffset}(x::ScalarOffset, y::Array{T}) = [x] .+ y  # Needed until v0.6
Base.:.+{T<:ScalarOffset}(x::Array{T}, y::ScalarOffset) = x .+ [y]  # Needed until v0.6

function Base.string(o::CompoundOffset)
    return "CompoundOffset($(join([string(offset) for offset in o.offsets], ", ")))"
end

Base.show(io::IO, o::CompoundOffset) = print(io, string(o))
