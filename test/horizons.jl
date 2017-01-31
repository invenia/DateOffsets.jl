winnipeg = TimeZone("America/Winnipeg")

@testset "Horizon" begin
    @testset "constructor" begin
        @test Horizon() == Horizon(Day(1), Hour(1), Day(1), Hour(0))
        @test Horizon(;
            coverage=Day(5),
            step=Hour(4),
            start_ceil=Minute(3),
            start_offset=Second(2)
        ) == Horizon(Day(5), Hour(4), Minute(3), Second(2))

        @test Horizon(Hour(1):Hour(24)) == Horizon(Hour(1):Hour(24), Hour(1))
        @test Horizon(Hour(1):Hour(24)) == Horizon(;
            coverage=Hour(24),
            step=Hour(1),
            start_ceil=Hour(1),
            start_offset=Hour(0)
        )
        @test Horizon(Minute(45):Minute(15):Minute(180), Hour(1)) == Horizon(;
            coverage=Minute(150),   # 2.5 hours
            step=Minute(15),
            start_ceil=Hour(1),
            start_offset=Minute(30)
        )
    end

    @testset "basic" begin
        sim_now = ZonedDateTime(2016, 1, 1, 9, 35, winnipeg)

        horizon = Horizon()
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 1, 2, 1, winnipeg),
            ZonedDateTime(2016, 1, 2, 2, winnipeg),
            ZonedDateTime(2016, 1, 2, 3, winnipeg),
            ZonedDateTime(2016, 1, 2, 4, winnipeg),
            ZonedDateTime(2016, 1, 2, 5, winnipeg),
            ZonedDateTime(2016, 1, 2, 6, winnipeg),
            ZonedDateTime(2016, 1, 2, 7, winnipeg),
            ZonedDateTime(2016, 1, 2, 8, winnipeg),
            ZonedDateTime(2016, 1, 2, 9, winnipeg),
            ZonedDateTime(2016, 1, 2, 10, winnipeg),
            ZonedDateTime(2016, 1, 2, 11, winnipeg),
            ZonedDateTime(2016, 1, 2, 12, winnipeg),
            ZonedDateTime(2016, 1, 2, 13, winnipeg),
            ZonedDateTime(2016, 1, 2, 14, winnipeg),
            ZonedDateTime(2016, 1, 2, 15, winnipeg),
            ZonedDateTime(2016, 1, 2, 16, winnipeg),
            ZonedDateTime(2016, 1, 2, 17, winnipeg),
            ZonedDateTime(2016, 1, 2, 18, winnipeg),
            ZonedDateTime(2016, 1, 2, 19, winnipeg),
            ZonedDateTime(2016, 1, 2, 20, winnipeg),
            ZonedDateTime(2016, 1, 2, 21, winnipeg),
            ZonedDateTime(2016, 1, 2, 22, winnipeg),
            ZonedDateTime(2016, 1, 2, 23, winnipeg),
            ZonedDateTime(2016, 1, 3, winnipeg)
        ]

        horizon = Horizon(;
            coverage=Day(2),
            step=Hour(2),
            start_offset=Day(-4),
            start_ceil=Week(1)
        )
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2015, 12, 31, 2, winnipeg),
            ZonedDateTime(2015, 12, 31, 4, winnipeg),
            ZonedDateTime(2015, 12, 31, 6, winnipeg),
            ZonedDateTime(2015, 12, 31, 8, winnipeg),
            ZonedDateTime(2015, 12, 31, 10, winnipeg),
            ZonedDateTime(2015, 12, 31, 12, winnipeg),
            ZonedDateTime(2015, 12, 31, 14, winnipeg),
            ZonedDateTime(2015, 12, 31, 16, winnipeg),
            ZonedDateTime(2015, 12, 31, 18, winnipeg),
            ZonedDateTime(2015, 12, 31, 20, winnipeg),
            ZonedDateTime(2015, 12, 31, 22, winnipeg),
            ZonedDateTime(2016, 1, 1, winnipeg),
            ZonedDateTime(2016, 1, 1, 2, winnipeg),
            ZonedDateTime(2016, 1, 1, 4, winnipeg),
            ZonedDateTime(2016, 1, 1, 6, winnipeg),
            ZonedDateTime(2016, 1, 1, 8, winnipeg),
            ZonedDateTime(2016, 1, 1, 10, winnipeg),
            ZonedDateTime(2016, 1, 1, 12, winnipeg),
            ZonedDateTime(2016, 1, 1, 14, winnipeg),
            ZonedDateTime(2016, 1, 1, 16, winnipeg),
            ZonedDateTime(2016, 1, 1, 18, winnipeg),
            ZonedDateTime(2016, 1, 1, 20, winnipeg),
            ZonedDateTime(2016, 1, 1, 22, winnipeg),
            ZonedDateTime(2016, 1, 2, winnipeg)
        ]
    end

    @testset "range" begin
        sim_now = ZonedDateTime(2016, 1, 1, 9, 35, winnipeg)

        horizon = Horizon(Hour(1):Hour(3))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 1, 1, 11, winnipeg),
            ZonedDateTime(2016, 1, 1, 12, winnipeg),
            ZonedDateTime(2016, 1, 1, 13, winnipeg)
        ]

        horizon = Horizon(Minute(15):Minute(15):Minute(120))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 1, 1, 10, winnipeg),
            ZonedDateTime(2016, 1, 1, 10, 15, winnipeg),
            ZonedDateTime(2016, 1, 1, 10, 30, winnipeg),
            ZonedDateTime(2016, 1, 1, 10, 45, winnipeg),
            ZonedDateTime(2016, 1, 1, 11, winnipeg),
            ZonedDateTime(2016, 1, 1, 11, 15, winnipeg),
            ZonedDateTime(2016, 1, 1, 11, 30, winnipeg),
            ZonedDateTime(2016, 1, 1, 11, 45, winnipeg)
        ]

        horizon = Horizon(Hour(1):Hour(3), Day(1))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 1, 2, 1, winnipeg),
            ZonedDateTime(2016, 1, 2, 2, winnipeg),
            ZonedDateTime(2016, 1, 2, 3, winnipeg)
        ]
    end

    @testset "spring forward" begin
        sim_now = ZonedDateTime(2016, 3, 12, 9, 35, winnipeg)
        horizon = Horizon()
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 3, 13, 1, winnipeg),
            ZonedDateTime(2016, 3, 13, 3, winnipeg),
            ZonedDateTime(2016, 3, 13, 4, winnipeg),
            ZonedDateTime(2016, 3, 13, 5, winnipeg),
            ZonedDateTime(2016, 3, 13, 6, winnipeg),
            ZonedDateTime(2016, 3, 13, 7, winnipeg),
            ZonedDateTime(2016, 3, 13, 8, winnipeg),
            ZonedDateTime(2016, 3, 13, 9, winnipeg),
            ZonedDateTime(2016, 3, 13, 10, winnipeg),
            ZonedDateTime(2016, 3, 13, 11, winnipeg),
            ZonedDateTime(2016, 3, 13, 12, winnipeg),
            ZonedDateTime(2016, 3, 13, 13, winnipeg),
            ZonedDateTime(2016, 3, 13, 14, winnipeg),
            ZonedDateTime(2016, 3, 13, 15, winnipeg),
            ZonedDateTime(2016, 3, 13, 16, winnipeg),
            ZonedDateTime(2016, 3, 13, 17, winnipeg),
            ZonedDateTime(2016, 3, 13, 18, winnipeg),
            ZonedDateTime(2016, 3, 13, 19, winnipeg),
            ZonedDateTime(2016, 3, 13, 20, winnipeg),
            ZonedDateTime(2016, 3, 13, 21, winnipeg),
            ZonedDateTime(2016, 3, 13, 22, winnipeg),
            ZonedDateTime(2016, 3, 13, 23, winnipeg),
            ZonedDateTime(2016, 3, 14, winnipeg)
        ]

        sim_now = ZonedDateTime(2016, 3, 12, 23, 59, winnipeg)
        horizon = Horizon(Hour(1):Hour(3), Day(1))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 3, 13, 1, winnipeg),
            ZonedDateTime(2016, 3, 13, 3, winnipeg),
            ZonedDateTime(2016, 3, 13, 4, winnipeg)
        ]

        sim_now = ZonedDateTime(2016, 3, 13, 0, 59, winnipeg)
        horizon = Horizon(Minute(15):Minute(15):Minute(120))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 3, 13, 1, 15, winnipeg),
            ZonedDateTime(2016, 3, 13, 1, 30, winnipeg),
            ZonedDateTime(2016, 3, 13, 1, 45, winnipeg),
            ZonedDateTime(2016, 3, 13, 3, winnipeg),
            ZonedDateTime(2016, 3, 13, 3, 15, winnipeg),
            ZonedDateTime(2016, 3, 13, 3, 30, winnipeg),
            ZonedDateTime(2016, 3, 13, 3, 45, winnipeg),
            ZonedDateTime(2016, 3, 13, 4, winnipeg)
        ]

        sim_now = ZonedDateTime(2016, 3, 12, 1, 30, winnipeg)
        horizon = Horizon(Day(0):Day(2), Hour(1))
        results = targets(horizon, sim_now)
        @test_throws NonExistentTimeError collect(results)

        sim_now = LaxZonedDateTime(sim_now)
        results = targets(horizon, sim_now)
        @test collect(results) == [
            LaxZonedDateTime(DateTime(2016, 3, 12, 2), winnipeg)
            LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg)    # DNE
            LaxZonedDateTime(DateTime(2016, 3, 14, 2), winnipeg)
        ]
    end

    @testset "fall back" begin
        sim_now = ZonedDateTime(2016, 11, 5, 9, 35, winnipeg)
        horizon = Horizon()
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
            ZonedDateTime(2016, 11, 6, 1, winnipeg, 2),
            ZonedDateTime(2016, 11, 6, 2, winnipeg),
            ZonedDateTime(2016, 11, 6, 3, winnipeg),
            ZonedDateTime(2016, 11, 6, 4, winnipeg),
            ZonedDateTime(2016, 11, 6, 5, winnipeg),
            ZonedDateTime(2016, 11, 6, 6, winnipeg),
            ZonedDateTime(2016, 11, 6, 7, winnipeg),
            ZonedDateTime(2016, 11, 6, 8, winnipeg),
            ZonedDateTime(2016, 11, 6, 9, winnipeg),
            ZonedDateTime(2016, 11, 6, 10, winnipeg),
            ZonedDateTime(2016, 11, 6, 11, winnipeg),
            ZonedDateTime(2016, 11, 6, 12, winnipeg),
            ZonedDateTime(2016, 11, 6, 13, winnipeg),
            ZonedDateTime(2016, 11, 6, 14, winnipeg),
            ZonedDateTime(2016, 11, 6, 15, winnipeg),
            ZonedDateTime(2016, 11, 6, 16, winnipeg),
            ZonedDateTime(2016, 11, 6, 17, winnipeg),
            ZonedDateTime(2016, 11, 6, 18, winnipeg),
            ZonedDateTime(2016, 11, 6, 19, winnipeg),
            ZonedDateTime(2016, 11, 6, 20, winnipeg),
            ZonedDateTime(2016, 11, 6, 21, winnipeg),
            ZonedDateTime(2016, 11, 6, 22, winnipeg),
            ZonedDateTime(2016, 11, 6, 23, winnipeg),
            ZonedDateTime(2016, 11, 7, winnipeg)
        ]

        sim_now = ZonedDateTime(2016, 11, 5, 23, 59, winnipeg)
        horizon = Horizon(Hour(1):Hour(3), Day(1))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
            ZonedDateTime(2016, 11, 6, 1, winnipeg, 2),
            ZonedDateTime(2016, 11, 6, 2, winnipeg)
        ]

        sim_now = ZonedDateTime(2016, 11, 6, 0, 59, winnipeg)
        horizon = Horizon(Minute(15):Minute(15):Minute(120))
        results = targets(horizon, sim_now)
        @test collect(results) == [
            ZonedDateTime(2016, 11, 6, 1, 15, winnipeg, 1),
            ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1),
            ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1),
            ZonedDateTime(2016, 11, 6, 1, winnipeg, 2),
            ZonedDateTime(2016, 11, 6, 1, 15, winnipeg, 2),
            ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 2),
            ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2),
            ZonedDateTime(2016, 11, 6, 2, winnipeg)
        ]

        sim_now = ZonedDateTime(2016, 11, 5, 0, 30, winnipeg)
        horizon = Horizon(Day(0):Day(2), Hour(1))
        results = targets(horizon, sim_now)
        @test_throws AmbiguousTimeError collect(results)

        sim_now = LaxZonedDateTime(sim_now)
        results = targets(horizon, sim_now)
        @test collect(results) == [
            LaxZonedDateTime(DateTime(2016, 11, 5, 1), winnipeg)
            LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg)    # AMB
            LaxZonedDateTime(DateTime(2016, 11, 7, 1), winnipeg)
        ]
    end
end
