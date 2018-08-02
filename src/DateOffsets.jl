__precompile__()

module DateOffsets

using Base.Dates
using TimeZones
using LaxZonedDateTimes
using Mocking
using AutoHashEquals
using Intervals
using Missings
using Compat: hasmethod

abstract type DateOffset end

const NowType = Union{ZonedDateTime, LaxZonedDateTime}
const TargetType = Union{AbstractInterval{<:NowType}, NowType}

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
