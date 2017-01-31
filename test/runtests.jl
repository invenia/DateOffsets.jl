import Mocking
Mocking.enable()

# Temporary. Currently tests require a special version of TimeZones.jl. In order to not mess
# up developers environments we'll only do this automatically in a CI enviroment.
if get(ENV, "CI", "false") == "true"
    Pkg.checkout("TimeZones", "graceful-zdt-range")
    Pkg.status()
end

using DateOffsets
using TimeZones
using LaxZonedDateTimes
using Base.Test
using Base.Dates

@testset "DateOffsets" begin
    include("horizons.jl")
    include("sourceoffsets.jl")
    include("observations.jl")
end
