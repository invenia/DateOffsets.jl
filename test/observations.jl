winnipeg = tz"America/Winnipeg"

@testset "observations" begin
    marketwide_offset(o) = floor(dynamicoffset(o.target; if_after=o.sim_now), Hour)

    @testset "no available targets" begin
        # None of the target dates are available (this is typically the case if the input
        # data are live actuals).
        horizon = Horizon(; step=Hour(1), span=Day(1))
        sim_now = ZonedDateTime(2016, 8, 11, 6, 15, winnipeg)

        s, t, o = observations([SimNow()], horizon, sim_now)

        @test s isa Vector{ZonedDateTime}
        @test t isa Vector{<:HourEnding{ZonedDateTime}}
        @test o isa Matrix{<:HourEnding{ZonedDateTime}}

        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        @test o == fill(HourEnding(sim_now), (24, 1))

        offsets = [
            StaticOffset(Hour(-1)),
            marketwide_offset,
        ]
        s, t, o = observations(offsets, horizon, sim_now)

        @test s isa Vector{ZonedDateTime}
        @test t isa Vector{<:HourEnding{ZonedDateTime}}
        @test o isa Matrix{<:HourEnding{ZonedDateTime}}

        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        expected = hcat(
            t .- Hour(1),
            HE.(vcat(
                ZonedDateTime(2016, 8, 11, 1, winnipeg):Hour(1):ZonedDateTime(2016, 8, 11, 6, winnipeg),
                ZonedDateTime(2016, 8, 10, 7, winnipeg):Hour(1):ZonedDateTime(2016, 8, 11, 0, winnipeg),
            )),
        )
        @test o == expected
    end

    @testset "some available targets" begin
        # Some of the target dates are available (this is typically the case if the input
        # data are forecasts).
        horizon = Horizon(; step=Hour(1), span=Day(1))
        sim_now = ZonedDateTime(2016, 8, 12, 12, winnipeg)

       offsets = [
            StaticOffset(Hour(-1)),
            marketwide_offset,
        ]
        s, t, o = observations(offsets, horizon, sim_now)

        @test s isa Vector{ZonedDateTime}
        @test t isa Vector{<:HourEnding{ZonedDateTime}}
        @test o isa Matrix{<:HourEnding{ZonedDateTime}}

        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        expected = hcat(
            t .- Hour(1),
            HE.(vcat(
                ZonedDateTime(2016, 8, 12, 1, winnipeg):Hour(1):ZonedDateTime(2016, 8, 12, 12, winnipeg),
                ZonedDateTime(2016, 8, 11, 13, winnipeg):Hour(1):ZonedDateTime(2016, 8, 12, 0, winnipeg),
            )),
        )
        @test o == expected
    end

    @testset "multiple dates" begin
        horizon = Horizon(; step=Hour(1), span=Day(1))

        sim_now = ZonedDateTime(2016, 8, 11, 6, 15, winnipeg)

        @testset "window" begin
            window = Day(0):Day(1):Day(2)
            training_sim_nows = [
                ZonedDateTime(2016, 8, 11, 6, 15, winnipeg),
                ZonedDateTime(2016, 8, 10, 6, 15, winnipeg),
                ZonedDateTime(2016, 8, 9, 6, 15, winnipeg),
            ]

            s, t, o = observations([SimNow(), BidTime()], horizon, window, sim_now)

            @test s isa Vector{ZonedDateTime}
            @test t isa Vector{<:HourEnding{ZonedDateTime}}
            @test o isa Matrix{<:HourEnding{ZonedDateTime}}

            @test s == repeat(training_sim_nows, inner=24)
            @test t == vcat([collect(targets(horizon, s)) for s in training_sim_nows]...)
            @test o ==  hcat(
                repeat(HourEnding.(training_sim_nows), inner=24),
                fill(HourEnding(sim_now), 72),
            )
        end

        @testset "vector" begin
            training_sim_nows = [
                ZonedDateTime(2016, 8, 9, 6, 15, winnipeg),
                ZonedDateTime(2016, 8, 10, 6, 15, winnipeg),
                ZonedDateTime(2016, 8, 11, 6, 15, winnipeg),
            ]
            offsets = [
                StaticOffset(Hour(-1)),
                marketwide_offset,
            ]
            s, t, o = observations(offsets, horizon, training_sim_nows, sim_now)

            @test s isa Vector{ZonedDateTime}
            @test t isa Vector{<:HourEnding{ZonedDateTime}}
            @test o isa Matrix{<:HourEnding{ZonedDateTime}}

            @test s == repeat(training_sim_nows, inner=24)
            @test t == vcat([collect(targets(horizon, s)) for s in training_sim_nows]...)

            obs = HE.(vcat(
                ZonedDateTime(2016, 8, 9, 1, winnipeg):Hour(1):ZonedDateTime(2016, 8, 9, 6, winnipeg),
                ZonedDateTime(2016, 8, 8, 7, winnipeg):Hour(1):ZonedDateTime(2016, 8, 9, 0, winnipeg),
            ))
            expected = hcat(
                t .- Hour(1),
                mapreduce(d -> d .+ obs, vcat, Day(0):Day(1):Day(2)),
            )
            @test o == expected
        end
    end

    @testset "spring forward" begin
        # DNE: 2016-03-13 02:00

        horizon = Horizon(; step=Hour(1), span=Day(1))
        offsets = [StaticOffset(Hour(2)), StaticOffset(Hour(24)), StaticOffset(Day(1))]
        sim_now = ZonedDateTime(2016, 3, 11, 12, 31, 12, winnipeg)

        @test_throws NonExistentTimeError observations(offsets,horizon,sim_now)

        s, t, o = observations(offsets, horizon, LaxZonedDateTime(sim_now))

        @test s isa Vector{LaxZonedDateTime}
        @test t isa Vector{<:HourEnding{LaxZonedDateTime}}
        @test o isa Matrix{<:HourEnding{LaxZonedDateTime}}

        @test s == fill(sim_now, (24))
        target_dates = HE.(LaxZonedDateTime.(
            DateTime(2016, 3, 12, 1):Hour(1):DateTime(2016, 3, 13, 0),
            winnipeg,
        ))

        @test t == target_dates

        # DNE Interval at [2,3]
        @test o == [target_dates .+ Hour(2) target_dates .+ Hour(24) target_dates .+ Day(1)]
    end

    @testset "fall back" begin
        # AMB: 2016-11-06 01:00

        horizon = Horizon(; step=Hour(1), span=Day(1))
        offsets = [StaticOffset(Hour(2)), StaticOffset(Hour(24)), StaticOffset(Day(1))]
        sim_now = ZonedDateTime(2016, 11, 4, 12, 31, 12, winnipeg)

        @test_throws AmbiguousTimeError observations(offsets, horizon, sim_now)

        s, t, o = observations(offsets, horizon, LaxZonedDateTime(sim_now))

        @test s isa Vector{LaxZonedDateTime}
        @test t isa Vector{<:HourEnding{LaxZonedDateTime}}
        @test o isa Matrix{<:HourEnding{LaxZonedDateTime}}

        @test s == fill(sim_now, (24))
        target_dates = HE.(LaxZonedDateTime.(
            DateTime(2016, 11, 5, 1):Hour(1):DateTime(2016, 11, 6, 0),
            winnipeg,
        ))
        @test t == target_dates

        # AMB Interval at [1,3]
        @test o == [target_dates .+ Hour(2) target_dates .+ Hour(24) target_dates .+ Day(1)]
    end
end
