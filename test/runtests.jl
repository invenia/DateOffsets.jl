using DateOffsets
using Dates
using Documenter
using Intervals
using LaxZonedDateTimes
using Mocking
using Test
using TimeZones

using DateOffsets: OffsetOrigins

Mocking.activate()

@testset "DateOffsets" begin
    include("horizons.jl")
    include("offsets.jl")
    include("observations.jl")

    VERSION >= v"1.6" && doctest(DateOffsets)
end
