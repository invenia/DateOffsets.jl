module DateOffsets

using AutoHashEquals
using Dates
using Intervals
using LaxZonedDateTimes
using TimeZones

export
    DateOffset,
    SourceOffset,
    Horizon,
    StaticOffset,
    DynamicOffset,
    FloorOffset,
    dynamicoffset,
    flooroffset,
    Target,
    SimNow,
    targets,
    observations

const NowType = Union{ZonedDateTime, LaxZonedDateTime}
const TargetType = Union{AbstractInterval{<:NowType}, NowType}

include("utils.jl")
include("horizons.jl")
include("offsets.jl")
include("observations.jl")

end #module
