module Offsets

using Base.Dates
using TimeZones
using LaxZonedDateTimes
#using DateUtils         # TODO: used?
#using DataSources
#using NullableArrays
using Intervals
using Mocking
# TODO: Some of the above aren't needed anymore

abstract Offset
typealias LZDT Union{ZonedDateTime, LaxZonedDateTime}

include("horizons.jl")
include("sourceoffsets.jl")
#include("utils.jl")    # TODO: this probably isn't needed.

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
