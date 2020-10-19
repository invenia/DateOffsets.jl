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

    # Note: The output of the doctests currently require an older version of Julia
    # https://github.com/JuliaLang/julia/pull/34387
    # We should update them to be compative with 1.5 or greater once EIS uses Julia v1.5
    if VERSION < v"1.5.0-DEV.163"
        doctest(DateOffsets)
    else
        @warn "Skipping doctests because they require an older version of Julia"
    end
end
