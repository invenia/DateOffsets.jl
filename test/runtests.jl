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

    doctest(DateOffsets)
end
