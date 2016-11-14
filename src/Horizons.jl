module Horizons

using Base.Dates
using TimeZones
using NullableArrays
using Intervals
using Mocking
using LaxZonedDateTimes
import Base: .+, +, .-, -
import TimeZones: Local, timezone, localtime, interpret

include("utils.jl")         # Should eventually go in base julia and/or DateUtils.jl
include("tables.jl")
include("offsets.jl")

export Table,
       horizon_hourly,
       horizon_daily,
       observation_dates,
       static_offset,
       recent_offset,
       dynamic_offset,
       dynamic_offset_hourofday,
       dynamic_offset_hourofweek,
       hourofweek

end
