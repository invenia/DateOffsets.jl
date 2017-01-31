module Offsets

using Base.Dates
using TimeZones
using LaxZonedDateTimes
using Intervals
using Mocking

abstract Offset
typealias LZDT Union{ZonedDateTime, LaxZonedDateTime}

include("horizons.jl")
include("sourceoffsets.jl")

export Offset,
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
