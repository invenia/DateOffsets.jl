@testset "observations" begin
    @testset "no available targets" begin
        # None of the target dates are available (this is typically the case if the input
        # data are live actuals).
        horizon = Horizon(; coverage=Day(1), step=Hour(1))
        sim_now = ZonedDateTime(2016, 8, 11, 12, 31, 12, winnipeg)
        latest = ZonedDateTime(2016, 8, 11, 6, 15, winnipeg)

        s, t, o = observations([LatestOffset()], horizon, sim_now, latest)
        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        @test o == fill(latest, (24, 1))

        offsets = [
            LatestOffset() + StaticOffset(Hour(-1)),
            DynamicOffset(; fallback=Day(-1))
        ]
        s, t, o = observations(offsets, horizon, sim_now, latest)
        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        expected = hcat(
            fill(latest, (24, 1)) .- Hour(1),
            [
                ZonedDateTime(2016, 8, 11, 1, winnipeg),
                ZonedDateTime(2016, 8, 11, 2, winnipeg),
                ZonedDateTime(2016, 8, 11, 3, winnipeg),
                ZonedDateTime(2016, 8, 11, 4, winnipeg),
                ZonedDateTime(2016, 8, 11, 5, winnipeg),
                ZonedDateTime(2016, 8, 11, 6, winnipeg),
                ZonedDateTime(2016, 8, 10, 7, winnipeg),
                ZonedDateTime(2016, 8, 10, 8, winnipeg),
                ZonedDateTime(2016, 8, 10, 9, winnipeg),
                ZonedDateTime(2016, 8, 10, 10, winnipeg),
                ZonedDateTime(2016, 8, 10, 11, winnipeg),
                ZonedDateTime(2016, 8, 10, 12, winnipeg),
                ZonedDateTime(2016, 8, 10, 13, winnipeg),
                ZonedDateTime(2016, 8, 10, 14, winnipeg),
                ZonedDateTime(2016, 8, 10, 15, winnipeg),
                ZonedDateTime(2016, 8, 10, 16, winnipeg),
                ZonedDateTime(2016, 8, 10, 17, winnipeg),
                ZonedDateTime(2016, 8, 10, 18, winnipeg),
                ZonedDateTime(2016, 8, 10, 19, winnipeg),
                ZonedDateTime(2016, 8, 10, 20, winnipeg),
                ZonedDateTime(2016, 8, 10, 21, winnipeg),
                ZonedDateTime(2016, 8, 10, 22, winnipeg),
                ZonedDateTime(2016, 8, 10, 23, winnipeg),
                ZonedDateTime(2016, 8, 11, 0, winnipeg)
            ]
        )
        @test o == expected
    end

    @testset "some available targets" begin
        # Some of the target dates are available (this is typically the case if the input
        # data are forecasts).
        horizon = Horizon(; coverage=Day(1), step=Hour(1))
        sim_now = ZonedDateTime(2016, 8, 11, 12, 31, 12, winnipeg)
        latest = ZonedDateTime(2016, 8, 12, 12, winnipeg)

        s, t, o = observations([LatestOffset()], horizon, sim_now, latest)
        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        expected = [
            [
                ZonedDateTime(2016, 8, 12, 1, winnipeg),
                ZonedDateTime(2016, 8, 12, 2, winnipeg),
                ZonedDateTime(2016, 8, 12, 3, winnipeg),
                ZonedDateTime(2016, 8, 12, 4, winnipeg),
                ZonedDateTime(2016, 8, 12, 5, winnipeg),
                ZonedDateTime(2016, 8, 12, 6, winnipeg),
                ZonedDateTime(2016, 8, 12, 7, winnipeg),
                ZonedDateTime(2016, 8, 12, 8, winnipeg),
                ZonedDateTime(2016, 8, 12, 9, winnipeg),
                ZonedDateTime(2016, 8, 12, 10, winnipeg),
                ZonedDateTime(2016, 8, 12, 11, winnipeg),
                ZonedDateTime(2016, 8, 12, 12, winnipeg)
            ];
            fill(latest, (12, 1))
        ]
        @test o == expected

        offsets = [
            LatestOffset() + StaticOffset(Hour(-1)),
            DynamicOffset(; fallback=Day(-1))
        ]
        s, t, o = observations(offsets, horizon, sim_now, latest)
        @test s == fill(sim_now, (24))
        @test t == collect(targets(horizon, sim_now))
        expected = hcat(
            [
                [
                    ZonedDateTime(2016, 8, 12, 1, winnipeg),
                    ZonedDateTime(2016, 8, 12, 2, winnipeg),
                    ZonedDateTime(2016, 8, 12, 3, winnipeg),
                    ZonedDateTime(2016, 8, 12, 4, winnipeg),
                    ZonedDateTime(2016, 8, 12, 5, winnipeg),
                    ZonedDateTime(2016, 8, 12, 6, winnipeg),
                    ZonedDateTime(2016, 8, 12, 7, winnipeg),
                    ZonedDateTime(2016, 8, 12, 8, winnipeg),
                    ZonedDateTime(2016, 8, 12, 9, winnipeg),
                    ZonedDateTime(2016, 8, 12, 10, winnipeg),
                    ZonedDateTime(2016, 8, 12, 11, winnipeg),
                    ZonedDateTime(2016, 8, 12, 12, winnipeg)
                ];
                fill(latest, (12, 1))
            ] .- Hour(1),
            [
                ZonedDateTime(2016, 8, 12, 1, winnipeg),
                ZonedDateTime(2016, 8, 12, 2, winnipeg),
                ZonedDateTime(2016, 8, 12, 3, winnipeg),
                ZonedDateTime(2016, 8, 12, 4, winnipeg),
                ZonedDateTime(2016, 8, 12, 5, winnipeg),
                ZonedDateTime(2016, 8, 12, 6, winnipeg),
                ZonedDateTime(2016, 8, 12, 7, winnipeg),
                ZonedDateTime(2016, 8, 12, 8, winnipeg),
                ZonedDateTime(2016, 8, 12, 9, winnipeg),
                ZonedDateTime(2016, 8, 12, 10, winnipeg),
                ZonedDateTime(2016, 8, 12, 11, winnipeg),
                ZonedDateTime(2016, 8, 12, 12, winnipeg),
                ZonedDateTime(2016, 8, 11, 13, winnipeg),
                ZonedDateTime(2016, 8, 11, 14, winnipeg),
                ZonedDateTime(2016, 8, 11, 15, winnipeg),
                ZonedDateTime(2016, 8, 11, 16, winnipeg),
                ZonedDateTime(2016, 8, 11, 17, winnipeg),
                ZonedDateTime(2016, 8, 11, 18, winnipeg),
                ZonedDateTime(2016, 8, 11, 19, winnipeg),
                ZonedDateTime(2016, 8, 11, 20, winnipeg),
                ZonedDateTime(2016, 8, 11, 21, winnipeg),
                ZonedDateTime(2016, 8, 11, 22, winnipeg),
                ZonedDateTime(2016, 8, 11, 23, winnipeg),
                ZonedDateTime(2016, 8, 12, 0, winnipeg)
            ]
        )
        @test o == expected
    end

    @testset "multiple dates" begin
        horizon = Horizon(; coverage=Day(1), step=Hour(1))
        sim_now = [
            ZonedDateTime(2016, 8, 11, 10, 31, 12, winnipeg),
            ZonedDateTime(2016, 8, 11, 11, 31, 12, winnipeg),
            ZonedDateTime(2016, 8, 11, 12, 31, 12, winnipeg)
        ]
        latest = [
            ZonedDateTime(2016, 8, 9, 6, 15, winnipeg),
            ZonedDateTime(2016, 8, 10, 6, 15, winnipeg),
            ZonedDateTime(2016, 8, 11, 6, 15, winnipeg)
        ]

        s, t, o = observations([LatestOffset()], horizon, sim_now, latest)
        @test s == repeat(sim_now, inner=24)
        @test t == vcat([collect(targets(horizon, s)) for s in sim_now]...)
        @test o == reshape(repeat(latest, inner=24), (72, 1))

        offsets = [
            LatestOffset() + StaticOffset(Hour(-1)),
            DynamicOffset(; fallback=Day(-1))
        ]
        s, t, o = observations(offsets, horizon, sim_now, latest)
        @test s == repeat(sim_now, inner=24)
        @test t == vcat([collect(targets(horizon, s)) for s in sim_now]...)
        expected = hcat(
            repeat(latest, inner=24) .- Hour(1),
            [
                ZonedDateTime(2016, 8, 9, 1, winnipeg),
                ZonedDateTime(2016, 8, 9, 2, winnipeg),
                ZonedDateTime(2016, 8, 9, 3, winnipeg),
                ZonedDateTime(2016, 8, 9, 4, winnipeg),
                ZonedDateTime(2016, 8, 9, 5, winnipeg),
                ZonedDateTime(2016, 8, 9, 6, winnipeg),
                ZonedDateTime(2016, 8, 8, 7, winnipeg),
                ZonedDateTime(2016, 8, 8, 8, winnipeg),
                ZonedDateTime(2016, 8, 8, 9, winnipeg),
                ZonedDateTime(2016, 8, 8, 10, winnipeg),
                ZonedDateTime(2016, 8, 8, 11, winnipeg),
                ZonedDateTime(2016, 8, 8, 12, winnipeg),
                ZonedDateTime(2016, 8, 8, 13, winnipeg),
                ZonedDateTime(2016, 8, 8, 14, winnipeg),
                ZonedDateTime(2016, 8, 8, 15, winnipeg),
                ZonedDateTime(2016, 8, 8, 16, winnipeg),
                ZonedDateTime(2016, 8, 8, 17, winnipeg),
                ZonedDateTime(2016, 8, 8, 18, winnipeg),
                ZonedDateTime(2016, 8, 8, 19, winnipeg),
                ZonedDateTime(2016, 8, 8, 20, winnipeg),
                ZonedDateTime(2016, 8, 8, 21, winnipeg),
                ZonedDateTime(2016, 8, 8, 22, winnipeg),
                ZonedDateTime(2016, 8, 8, 23, winnipeg),
                ZonedDateTime(2016, 8, 9, 0, winnipeg),
                ZonedDateTime(2016, 8, 10, 1, winnipeg),
                ZonedDateTime(2016, 8, 10, 2, winnipeg),
                ZonedDateTime(2016, 8, 10, 3, winnipeg),
                ZonedDateTime(2016, 8, 10, 4, winnipeg),
                ZonedDateTime(2016, 8, 10, 5, winnipeg),
                ZonedDateTime(2016, 8, 10, 6, winnipeg),
                ZonedDateTime(2016, 8, 9, 7, winnipeg),
                ZonedDateTime(2016, 8, 9, 8, winnipeg),
                ZonedDateTime(2016, 8, 9, 9, winnipeg),
                ZonedDateTime(2016, 8, 9, 10, winnipeg),
                ZonedDateTime(2016, 8, 9, 11, winnipeg),
                ZonedDateTime(2016, 8, 9, 12, winnipeg),
                ZonedDateTime(2016, 8, 9, 13, winnipeg),
                ZonedDateTime(2016, 8, 9, 14, winnipeg),
                ZonedDateTime(2016, 8, 9, 15, winnipeg),
                ZonedDateTime(2016, 8, 9, 16, winnipeg),
                ZonedDateTime(2016, 8, 9, 17, winnipeg),
                ZonedDateTime(2016, 8, 9, 18, winnipeg),
                ZonedDateTime(2016, 8, 9, 19, winnipeg),
                ZonedDateTime(2016, 8, 9, 20, winnipeg),
                ZonedDateTime(2016, 8, 9, 21, winnipeg),
                ZonedDateTime(2016, 8, 9, 22, winnipeg),
                ZonedDateTime(2016, 8, 9, 23, winnipeg),
                ZonedDateTime(2016, 8, 10, 0, winnipeg),
                ZonedDateTime(2016, 8, 11, 1, winnipeg),
                ZonedDateTime(2016, 8, 11, 2, winnipeg),
                ZonedDateTime(2016, 8, 11, 3, winnipeg),
                ZonedDateTime(2016, 8, 11, 4, winnipeg),
                ZonedDateTime(2016, 8, 11, 5, winnipeg),
                ZonedDateTime(2016, 8, 11, 6, winnipeg),
                ZonedDateTime(2016, 8, 10, 7, winnipeg),
                ZonedDateTime(2016, 8, 10, 8, winnipeg),
                ZonedDateTime(2016, 8, 10, 9, winnipeg),
                ZonedDateTime(2016, 8, 10, 10, winnipeg),
                ZonedDateTime(2016, 8, 10, 11, winnipeg),
                ZonedDateTime(2016, 8, 10, 12, winnipeg),
                ZonedDateTime(2016, 8, 10, 13, winnipeg),
                ZonedDateTime(2016, 8, 10, 14, winnipeg),
                ZonedDateTime(2016, 8, 10, 15, winnipeg),
                ZonedDateTime(2016, 8, 10, 16, winnipeg),
                ZonedDateTime(2016, 8, 10, 17, winnipeg),
                ZonedDateTime(2016, 8, 10, 18, winnipeg),
                ZonedDateTime(2016, 8, 10, 19, winnipeg),
                ZonedDateTime(2016, 8, 10, 20, winnipeg),
                ZonedDateTime(2016, 8, 10, 21, winnipeg),
                ZonedDateTime(2016, 8, 10, 22, winnipeg),
                ZonedDateTime(2016, 8, 10, 23, winnipeg),
                ZonedDateTime(2016, 8, 11, 0, winnipeg)
            ]
        )
        @test o == expected
    end

    @testset "spring forward" begin
        # DNE: 2016-03-13 02:00

        horizon = Horizon(; coverage=Day(1), step=Hour(1))
        offsets = [StaticOffset(Hour(2)), StaticOffset(Hour(24)), StaticOffset(Day(1))]
        sim_now = ZonedDateTime(2016, 3, 11, 12, 31, 12, winnipeg)
        latest = ZonedDateTime(2016, 3, 11, 6, 15, winnipeg)

        @test_throws NonExistentTimeError observations(offsets, horizon, sim_now, latest)

        s, t, o = observations(offsets, horizon, LaxZonedDateTime(sim_now), latest)
        @test s == fill(sim_now, (24))
        target_dates = [
            LaxZonedDateTime(DateTime(2016, 3, 12, 1), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 2), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 3), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 4), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 5), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 6), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 7), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 8), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 9), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 10), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 11), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 12), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 13), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 14), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 15), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 16), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 17), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 18), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 19), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 20), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 21), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 22), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 12, 23), winnipeg),
            LaxZonedDateTime(DateTime(2016, 3, 13, 0), winnipeg)
        ]
        @test t == target_dates
        @test o == [target_dates + Hour(2) target_dates + Hour(24) target_dates + Day(1)]
    end

    @testset "fall back" begin
        # AMB: 2016-11-06 01:00

        horizon = Horizon(; coverage=Day(1), step=Hour(1))
        offsets = [StaticOffset(Hour(2)), StaticOffset(Hour(24)), StaticOffset(Day(1))]
        sim_now = ZonedDateTime(2016, 11, 4, 12, 31, 12, winnipeg)
        latest = ZonedDateTime(2016, 11, 4, 6, 15, winnipeg)

        @test_throws AmbiguousTimeError observations(offsets, horizon, sim_now, latest)

        s, t, o = observations(offsets, horizon, LaxZonedDateTime(sim_now), latest)
        @test s == fill(sim_now, (24))
        target_dates = [
            LaxZonedDateTime(DateTime(2016, 11, 5, 1), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 2), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 3), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 4), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 5), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 6), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 7), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 8), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 9), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 10), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 11), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 12), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 13), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 14), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 15), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 16), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 17), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 18), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 19), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 20), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 21), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 22), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 5, 23), winnipeg),
            LaxZonedDateTime(DateTime(2016, 11, 6, 0), winnipeg)
        ]
        @test t == target_dates
        @test o == [target_dates + Hour(2) target_dates + Hour(24) target_dates + Day(1)]
    end
end