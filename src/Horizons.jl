module Horizons

using Base.Dates
using TimeZones
import Base: .+, +, .-, -

include("intervals.jl")     # Originally from AxisArrays.jl
include("tables.jl")
include("offsets.jl")
include("utils.jl")         # Should eventually go in base julia and/or DateUtils.jl

export Interval,
       Table,
       horizon_hourly,
       horizon_next_day,
       observation_dates,
       static_offset,
       recent_offset,
       dynamic_offset,
       dynamic_offset_hourofday,
       dynamic_offset_hourofweek,
       hourofweek

end
