module Offsets

using Base.Dates
using TimeZones
#using LaxZonedDateTimes
using DateUtils         # TODO: used?
using DataSources
#using NullableArrays
using Intervals
using Mocking
# TODO: Some of the above aren't needed anymore

import Base.show

include("types.jl")
#include("utils.jl")    # TODO: this probably isn't needed.
include("dates.jl")

export Offset,
       Horizon,
       SourceOffset,
       StaticOffset,
       LatestOffset,
       DynamicOffset,
       CustomOffset,    # TODO add tests for this
       targets,
       apply,
       observations

end
