__precompile__()

module DateOffsets

using AutoHashEquals
using Compat.Dates
using Compat: hasmethod, nameof
using Intervals
using LaxZonedDateTimes
using Missings
using TimeZones

abstract type DateOffset end

const NowType = Union{ZonedDateTime, LaxZonedDateTime}
const TargetType = Union{AbstractInterval{<:NowType}, NowType}

include("utils.jl")
include("horizons.jl")
include("sourceoffsets.jl")
include("observations.jl")

export DateOffset,
       Horizon,
       SourceOffset,
       ScalarOffset,
       StaticOffset,
       LatestOffset,
       DynamicOffset,
       CustomOffset,
       CompoundOffset,
       targets,
       apply,
       observations

end
