winnipeg = tz"America/Winnipeg"

@testset "Accessors" begin
    @testset "Target" begin
        @testset "basic" begin
            offset = Target()
            @test offset isa DateOffset

            sim_now = ZonedDateTime(2016, 8, 11, 3, winnipeg)
            target = HourEnding(ZonedDateTime(2016, 8, 11, 8, winnipeg))

            @test offset(OffsetOrigins(target, sim_now)) isa AnchoredInterval
            @test offset(OffsetOrigins(target, sim_now)) == target

            target = HourEnding(ZonedDateTime(2016, 8, 11, 1, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) == target

            sim_now = ZonedDateTime(2016, 8, 12, 4, winnipeg)
            @test offset(OffsetOrigins(target, sim_now)) == target
        end

        @testset "CompoundOffset" begin
            sim_now = ZonedDateTime(2016, 8, 11, 3, winnipeg)
            offset = StaticOffset(Target(), Hour(2))

            target = HE(ZonedDateTime(2016, 8, 11, 5, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) == target + Hour(2)

            target = HE(ZonedDateTime(2016, 8, 10, 1, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) == target + Hour(2)
        end
    end

    @testset "SimNow" begin
        @testset "basic" begin
            offset = SimNow()
            @test offset isa DateOffset

            sim_now = ZonedDateTime(2016, 8, 11, 3, winnipeg)

            target = HourEnding(ZonedDateTime(2016, 8, 11, 8, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) isa AnchoredInterval
            @test offset(OffsetOrigins(target, sim_now)) == HourEnding(sim_now)

            target = HourEnding(ZonedDateTime(2016, 8, 11, 1, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) == HourEnding(sim_now)

            sim_now = ZonedDateTime(2016, 8, 12, 4, winnipeg)
            @test offset(OffsetOrigins(target, sim_now)) == HourEnding(sim_now)
        end

        @testset "CompoundOffset" begin
            sim_now = ZonedDateTime(2016, 8, 11, 3, 30, winnipeg)
            offset = StaticOffset(SimNow(), Hour(2))

            target = HE(ZonedDateTime(2016, 8, 11, 5, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) == HourEnding(sim_now + Hour(2))

            target = HE(ZonedDateTime(2016, 8, 10, 1, winnipeg))
            @test offset(OffsetOrigins(target, sim_now)) == HourEnding(sim_now + Hour(2))

            sim_now = ZonedDateTime(2016, 8, 12, 1, 30, winnipeg)
            @test offset(OffsetOrigins(target, sim_now)) == HourEnding(sim_now + Hour(2))
        end
    end
end

@testset "StaticOffset" begin
    @testset "basic" begin
        @test StaticOffset(Day(-1)) isa DateOffset

        he = HourEnding(ZonedDateTime(2016, 1, 2, 1, winnipeg))
        sim_now = ZonedDateTime(2015, 1, 2, 1, winnipeg)
        origins = OffsetOrigins(he, sim_now)

        result = StaticOffset(Second(0))(origins)
        @test result == he

        result = StaticOffset(Minute(-15))(origins)
        @test result == HourEnding(ZonedDateTime(2016, 1, 2, 0, 45, winnipeg))

        result = StaticOffset(Hour(6))(origins)
        @test result == HourEnding(ZonedDateTime(2016, 1, 2, 7, winnipeg))

        result = StaticOffset(Day(-1))(origins)
        @test result == HourEnding(ZonedDateTime(2016, 1, 1, 1, winnipeg))

        result = StaticOffset(Target(), Week(2))(origins)
        @test result == HourEnding(ZonedDateTime(2016, 1, 16, 1, winnipeg))

        result = StaticOffset(SimNow(), Minute(-15))(origins)
        @test result == HourEnding(ZonedDateTime(2015, 1, 2, 0, 45, winnipeg))

        result = StaticOffset(SimNow(), Hour(6))(origins)
        @test result == HourEnding(ZonedDateTime(2015, 1, 2, 7, winnipeg))

        result = StaticOffset(SimNow(), Week(2))(origins)
        @test result == HourEnding(ZonedDateTime(2015, 1, 16, 1, winnipeg))
    end


    @testset "spring forward" begin
        sim_now = ZonedDateTime(2015, winnipeg)

        he = HourEnding(ZonedDateTime(2016, 3, 13, 1, winnipeg))
        result = StaticOffset(Minute(90))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 3, 13, 3, 30, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 3, 13, winnipeg))
        result = StaticOffset(Hour(2))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 3, 13, 3, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 3, 13, 3, winnipeg))
        result = StaticOffset(Minute(-15))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 3, 13, 1, 45, winnipeg))

        # 23 hour day
        he = HourEnding(ZonedDateTime(2016, 3, 13, winnipeg))
        result = StaticOffset(Hour(24))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 3, 14, 1, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 3, 13, winnipeg))
        result =StaticOffset(Day(1))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 3, 14, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 3, 12, 2, winnipeg))
        @test_throws NonExistentTimeError StaticOffset(Day(1))(OffsetOrigins(he, sim_now))  # DNE

        # DNE LaxZonedDateTime where one of the endpoints is INVALID
        he = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 3, 12, 2, winnipeg)))
        result = StaticOffset(Day(1))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg))
    end

    @testset "fall back" begin
        sim_now = ZonedDateTime(2015, winnipeg)

        he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
        result = StaticOffset(Minute(90))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1))

        he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
        result = StaticOffset(Minute(150))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 2))

        he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
        result = StaticOffset(Hour(3))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg))
        result = StaticOffset(Minute(-15))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2))

        he = HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg))
        result = StaticOffset(Minute(-75))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1))

        # 25 hour day
        he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
        result = StaticOffset(Hour(24))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 6, 23, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
        result = StaticOffset(Day(1))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(ZonedDateTime(2016, 11, 7, winnipeg))

        he = HourEnding(ZonedDateTime(2016, 11, 5, 1, winnipeg))
        @test_throws AmbiguousTimeError StaticOffset(Day(1))(OffsetOrigins(he, sim_now))  # AMB

        # AMB LaxZonedDateTime where one of the endpoints is INVALID
        he = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 11, 5, 1, winnipeg)))
        result = StaticOffset(Day(1))(OffsetOrigins(he, sim_now))
        @test result == HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg))
    end
end

@testset "FloorOffset" begin
    target = HourEnding(ZonedDateTime(2016, 1, 2, 1, winnipeg))  # Saturday
    sim_now = ZonedDateTime(2015, 1, 2, 1, 30, winnipeg)  # Friday
    origins = OffsetOrigins(target, sim_now)

    @testset "target" begin
        base = Target()
        result = FloorOffset(base, Hour)(origins)
        @test result == HourEnding(ZonedDateTime(2016, 1, 2, 1, winnipeg))

        result = FloorOffset(base, Day)(origins)
        @test result == HourEnding(ZonedDateTime(2016, 1, 2, winnipeg))

        result = FloorOffset(base, Week)(origins)
        @test result == HourEnding(ZonedDateTime(2015, 12, 28, winnipeg))
    end

    @testset "sim_now" begin
        base = SimNow()
        result = FloorOffset(base, Hour)(origins)
        @test result == HourEnding(ZonedDateTime(2015, 1, 2, 1, winnipeg))

        result = FloorOffset(base, Day)(origins)
        @test result == HourEnding(ZonedDateTime(2015, 1, 2, winnipeg))

        result = FloorOffset(base, Week)(origins)
        @test result == HourEnding(ZonedDateTime(2014, 12, 29, winnipeg))
    end
end

@testset "DynamicOffset" begin
    @testset "constructor" begin
        @test DynamicOffset() isa DateOffset
        @test_throws ArgumentError DynamicOffset(; fallback=Day(1))
    end

    @testset "basic" begin
        default_fallback = DynamicOffset(; if_after=SimNow())
        match_hod = DynamicOffset(; fallback=Day(-1), if_after=SimNow())
        match_how = DynamicOffset(; fallback=Week(-1), if_after=SimNow())
        match_hod_tuesday = DynamicOffset(; match=t -> dayofweek(t) == Tuesday, if_after=SimNow())

        sim_now = ZonedDateTime(2016, 8, 11, 10, winnipeg)
        target = HE(ZonedDateTime(2016, 8, 11, 8, winnipeg))  # Thursday
        origins = OffsetOrigins(target, sim_now)

        @testset "data available" begin
            # Data for target date should be available (according to sim_now).
            @test default_fallback(origins) == match_hod(origins)
            @test match_hod(origins) == target
            @test match_how(origins) == target
            @test match_hod_tuesday(origins) == target - Day(2)
        end

        sim_now = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)
        origins = OffsetOrigins(target, sim_now)

        @testset "fall back once" begin
            # Data for target date aren't available, so fall back.
            @test default_fallback(origins) == match_hod(origins)
            @test match_hod(origins) == target - Day(1)
            @test match_how(origins) == target - Week(1)
            @test match_hod_tuesday(origins) == target - Day(2)
        end

        sim_now = ZonedDateTime(2016, 8, 1, 1, 15, winnipeg)
        origins = OffsetOrigins(target, sim_now)

        @testset "fall back more" begin
            # Data for target date aren't available, so fall back more.
            @test default_fallback(origins) == match_hod(origins)
            @test match_hod(origins) == target - Day(11)
            @test match_how(origins) == target - Week(2)
            @test match_hod_tuesday(origins) == target - Day(16)
        end

        @testset "default if_after" begin
            default = DynamicOffset()
            match_hod = DynamicOffset(; fallback=Day(-1), if_after=Target())
            match_how = DynamicOffset(; fallback=Week(-1))
            match_hod_tuesday = DynamicOffset(; match=t -> dayofweek(t) == Tuesday)

            @test default(origins) == match_hod(origins)
            @test match_hod(origins) == target
            @test match_how(origins) == target
            @test match_hod_tuesday(origins) == target - Day(2)
        end

        @testset "change target" begin
            sim_now = ZonedDateTime(2016, 8, 1, 1, 15, winnipeg)  # Monday
            origins = OffsetOrigins(target, sim_now)

            match_hod = DynamicOffset(SimNow(); if_after=SimNow())
            match_how = DynamicOffset(SimNow(); fallback=Week(-1), if_after=SimNow())
            match_hod_tuesday = DynamicOffset(SimNow(); match=t -> dayofweek(t) == Tuesday, if_after=SimNow())

            @test match_hod(origins) == HourEnding(sim_now)
            @test match_how(origins) == HourEnding(sim_now)
            @test match_hod_tuesday(origins) == HourEnding(sim_now) - Day(6)

            target = HE(ZonedDateTime(2016, 7, 30, 8, winnipeg))
            origins = OffsetOrigins(target, sim_now)

            match_hod = DynamicOffset(SimNow())
            match_how = DynamicOffset(SimNow(); fallback=Week(-1))
            match_hod_tuesday = DynamicOffset(SimNow(); match=t -> dayofweek(t) == Tuesday)

            @test match_hod(origins) == HourEnding(sim_now) - Day(2)
            @test match_how(origins) == HourEnding(sim_now) - Week(1)
            @test match_hod_tuesday(origins) == HourEnding(sim_now) - Day(6)
        end

        @testset "direct" begin
            target = HE(ZonedDateTime(2016, 8, 11, 8, winnipeg))  # Thursday
            origins = OffsetOrigins(target, sim_now)

            match_hod(o) = dynamicoffset(o.target; if_after=o.sim_now)
            match_how(o) = dynamicoffset(o.target; fallback=Week(-1), if_after=o.sim_now)
            match_hod_tuesday(o) = dynamicoffset(o.target; match=t -> dayofweek(t) == Tuesday, if_after=o.sim_now)

            @test match_hod(origins) == target - Day(11)
            @test match_how(origins) == target - Week(2)
            @test match_hod_tuesday(origins) == target - Day(16)
        end
    end

    @testset "spring forward" begin
        match_hod = DynamicOffset(; fallback=Day(-1), if_after=SimNow())
        sim_now = ZonedDateTime(2016, 3, 14, 1, winnipeg)

        target = HourEnding(ZonedDateTime(2016, 3, 14, 2, winnipeg))
        @test_throws NonExistentTimeError match_hod(OffsetOrigins(target, sim_now))

        # DNE LaxZonedDateTime where one of the endpoints is INVALID
        target = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 3, 14, 2, winnipeg)))
        result = match_hod(OffsetOrigins(target, sim_now))
        @test result == HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg))
    end

    @testset "fall back" begin
        match_hod = DynamicOffset(; fallback=Day(-1), if_after=SimNow())
        sim_now = ZonedDateTime(2016, 11, 7, winnipeg)

        target = HourEnding(ZonedDateTime(2016, 11, 7, 1, winnipeg))
        @test_throws AmbiguousTimeError match_hod(OffsetOrigins(target, sim_now))

        # AMB LaxZonedDateTime where one of the endpoints is INVALID
        target = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 11, 7, 1, winnipeg)))
        result = match_hod(OffsetOrigins(target, sim_now))
        @test result == HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg))
    end
end

@testset "CustomOffset" begin
    offset_fn(o) = (hour(anchor(o.sim_now)) ≥ 18) ? HE(anchor(o.sim_now)) : o.target

    sim_now_base = ZonedDateTime(2016, 8, 10, 0, 31, 12, winnipeg)
    target = HourEnding(ZonedDateTime(2016, 8, 11, 2, winnipeg))
    for h in 0:17
        sim_now = sim_now_base + Hour(h)
        @test offset_fn(OffsetOrigins(target, sim_now)) == target
    end
    for h in 18:23
        sim_now = sim_now_base + Hour(h)
        @test offset_fn(OffsetOrigins(target, sim_now)) == HE(sim_now)
    end
end

