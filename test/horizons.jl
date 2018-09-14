winnipeg = tz"America/Winnipeg"

@testset "Horizon" begin
    @testset "constructor" begin
        @test Horizon() == Horizon(DateOffsets._start_func, Hour(1), Day(1))
        @test Horizon(; step=Hour(5), span=Day(4)) ==
            Horizon(DateOffsets._start_func, Hour(5), Day(4))
    end

    @testset "basic" begin
        sim_now = ZonedDateTime(2016, 1, 1, 9, 35, winnipeg)

        horizon = Horizon()
        results = targets(horizon, sim_now)
        @test collect(results) == collect(
            HourEnding(ZonedDateTime(2016, 1, 2, 1, winnipeg)):
            HourEnding(ZonedDateTime(2016, 1, 3, winnipeg))
        )

        horizon = Horizon(; step=Hour(2), span=Day(2)) do s
            ceil(s, Week) - Day(4)
        end
        results = targets(horizon, sim_now)
        @test collect(results) == collect(
            AnchoredInterval{Hour(-2)}(ZonedDateTime(2015, 12, 31, 2, winnipeg)):
            AnchoredInterval{Hour(-2)}(ZonedDateTime(2016, 1, 2, winnipeg))
        )
    end

    @testset "spring forward" begin
        sim_now = ZonedDateTime(2016, 3, 12, 9, 35, winnipeg)
        horizon = Horizon()
        results = targets(horizon, sim_now)
        @test collect(results) == [
            HourEnding(ZonedDateTime(2016, 3, 13, 1, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 3, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 4, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 5, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 6, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 7, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 8, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 9, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 10, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 11, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 12, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 13, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 14, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 15, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 16, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 17, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 18, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 19, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 20, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 21, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 22, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 23, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 14, winnipeg)),
        ]

        sim_now = ZonedDateTime(2016, 3, 12, 23, 59, winnipeg)
        horizon = Horizon(; step=Hour(1), span=Hour(3))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            HourEnding(ZonedDateTime(2016, 3, 13, 1, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 3, winnipeg)),
            HourEnding(ZonedDateTime(2016, 3, 13, 4, winnipeg)),
        ]

        sim_now = ZonedDateTime(2016, 3, 13, 0, 59, winnipeg)
        horizon = Horizon(; step=Minute(15), span=Minute(120)) do s
             ceil(s, Minute(15))
        end
        results = targets(horizon, sim_now)
        @test collect(results) == [
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 1, 15, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 1, 30, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 1, 45, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 3, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 3, 15, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 3, 30, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 3, 45, winnipeg)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 3, 13, 4, winnipeg)),
        ]

        sim_now = ZonedDateTime(2016, 3, 12, 1, 30, winnipeg)
        horizon = Horizon(; step=Day(1), span=Day(3)) do s
            ceil(s, Hour) - Day(1)
        end
        @test_throws NonExistentTimeError collect(targets(horizon, sim_now))
        # Depending on the version of Julia, the error will be thrown either by the call to
        # targets or by the collect. (The distinction isn't deemed particularly important.)

        sim_now = LaxZonedDateTime(sim_now)
        results = targets(horizon, sim_now)
        @test collect(results) == [
            AnchoredInterval{Day(-1)}(LaxZonedDateTime(DateTime(2016, 3, 12, 2), winnipeg)),
            AnchoredInterval{Day(-1)}(LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg)),
            AnchoredInterval{Day(-1)}(LaxZonedDateTime(DateTime(2016, 3, 14, 2), winnipeg)),
        ]
    end

    @testset "fall back" begin
        sim_now = ZonedDateTime(2016, 11, 5, 9, 35, winnipeg)
        horizon = Horizon()
        results = targets(horizon, sim_now)
        @test collect(results) == [
            HourEnding(ZonedDateTime(2016, 11, 6, 1, winnipeg, 1)),
            HourEnding(ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)),
            HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 3, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 4, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 5, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 6, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 7, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 8, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 9, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 10, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 11, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 12, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 13, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 14, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 15, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 16, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 17, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 18, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 19, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 20, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 21, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 22, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 6, 23, winnipeg)),
            HourEnding(ZonedDateTime(2016, 11, 7, winnipeg)),
        ]

        sim_now = ZonedDateTime(2016, 11, 5, 23, 59, winnipeg)
        horizon = Horizon(; step=Hour(1), span=Hour(3))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            HourEnding(ZonedDateTime(2016, 11, 6, 1, winnipeg, 1)),
            HourEnding(ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)),
            HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg)),
        ]

        sim_now = ZonedDateTime(2016, 11, 6, 0, 59, winnipeg)
        horizon = Horizon(; step=Minute(15), span=Minute(120)) do s
            ceil(s, Minute(15))
        end
        results = targets(horizon, sim_now)
        @test collect(results) == [
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, 15, winnipeg, 1)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, 15, winnipeg, 2)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 2)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)),
            AnchoredInterval{Minute(-15)}(ZonedDateTime(2016, 11, 6, 2, winnipeg)),
        ]

        sim_now = ZonedDateTime(2016, 11, 5, 0, 30, winnipeg)
        horizon = Horizon(; step=Day(1), span=Day(3)) do s
            ceil(s, Hour) - Day(1)
        end
        @test_throws AmbiguousTimeError collect(targets(horizon, sim_now))
        # Depending on the version of Julia, the error will be thrown either by the call to
        # targets or by the collect. (The distinction isn't deemed particularly important.)

        sim_now = LaxZonedDateTime(sim_now)
        results = targets(horizon, sim_now)
        @test collect(results) == [
            AnchoredInterval{Day(-1)}(LaxZonedDateTime(DateTime(2016, 11, 5, 1), winnipeg)),
            AnchoredInterval{Day(-1)}(LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg)),
            AnchoredInterval{Day(-1)}(LaxZonedDateTime(DateTime(2016, 11, 7, 1), winnipeg)),
        ]
    end

    @testset "last hour of day" begin
        sim_now = ZonedDateTime(2018, 8, 2, 14, winnipeg)
        horizon = Horizon(step=Hour(1), span=Hour(1)) do sim_now
            ceil(sim_now, Day) + Day(1) - Hour(1)
        end

        results = targets(horizon, sim_now)
        @test collect(results) == [
            AnchoredInterval{Hour(-1)}(ZonedDateTime(DateTime(2018, 8, 4), winnipeg)),
        ]
    end

    @testset "output" begin
        start_function(s) = ceil(s, Minute(15)) + Minute(30)
        horizon = Horizon(start_function, step=Minute(15), span=Day(5))

        @testset "show" begin
            @test sprint(show, Horizon()) == "Horizon(step=Hour(1), span=Day(1))"
            @test sprint(show, horizon) == "Horizon(start_function, step=Minute(15), span=Day(5))"
        end

        @testset "print" begin
            @test sprint(print, Horizon()) == "Horizon(1 day at 1 hour resolution)"
            @test sprint(print, horizon) == (
                "Horizon(5 days at 15 minutes resolution, " *
                "start_fn: start_function)"
            )
        end
    end
end
