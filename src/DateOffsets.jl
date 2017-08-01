module DateOffsets

using Base.Dates
using TimeZones
using LaxZonedDateTimes
using Mocking

abstract type DateOffset end
const LZDT = Union{ZonedDateTime, LaxZonedDateTime}

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
