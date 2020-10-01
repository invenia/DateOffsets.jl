module DateOffsets

using AutoHashEquals
using Dates
using Intervals
using LaxZonedDateTimes
using TimeZones

export
    DateOffset,
    Horizon,
    SourceOffset,
    ScalarOffset,
    StaticOffset,
    LatestOffset,
    SimNowOffset,
    DynamicOffset,
    CustomOffset,
    CompoundOffset,
    AnchoredOffset,
    targets,
    apply,
    observations,
    LATEST_OFFSET,
    SIM_NOW_OFFSET

abstract type DateOffset end

const NowType = Union{ZonedDateTime, LaxZonedDateTime}
const TargetType = Union{AbstractInterval{<:NowType}, NowType}

include("utils.jl")
include("horizons.jl")
include("sourceoffsets.jl")
include("observations.jl")

end #module
