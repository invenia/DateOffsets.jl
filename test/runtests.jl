using DateOffsets
using Dates
using Documenter
using Intervals
using LaxZonedDateTimes
using Test
using TimeZones

using DateOffsets: OffsetOrigins

@testset "DateOffsets" begin
    include("horizons.jl")
    include("offsets.jl")
    include("observations.jl")

    if VERSION >= v"1.6.0"
        doctest(DateOffsets)
    end
end
