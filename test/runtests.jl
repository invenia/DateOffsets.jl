using DateOffsets
using Dates
using Documenter
using Intervals
using LaxZonedDateTimes
using Test
using TimeZones

@testset "DateOffsets" begin
    include("horizons.jl")
    include("sourceoffsets.jl")
    include("observations.jl")
    doctest(DateOffsets)
end
