winnipeg = TimeZone("America/Winnipeg")

@testset "StaticOffset" begin
    @testset "basic" begin
        dt = ZonedDateTime(2016, 1, 2, 1, winnipeg)

        result = apply(StaticOffset(Second(0)), dt)
        @test result == dt

        result = apply(StaticOffset(Minute(-15)), dt)
        @test result == ZonedDateTime(2016, 1, 2, 0, 45, winnipeg)

        result = apply(StaticOffset(Hour(6)), dt)
        @test result == ZonedDateTime(2016, 1, 2, 7, winnipeg)

        result = apply(StaticOffset(Day(-1)), dt)
        @test result == ZonedDateTime(2016, 1, 1, 1, winnipeg)

        result = apply(StaticOffset(Week(2)), dt)
        @test result == ZonedDateTime(2016, 1, 16, 1, winnipeg)
    end

    @testset "spring forward" begin
        dt = ZonedDateTime(2016, 3, 13, 1, winnipeg)
        result = apply(StaticOffset(Minute(90)), dt)
        @test result == ZonedDateTime(2016, 3, 13, 3, 30, winnipeg)

        dt = ZonedDateTime(2016, 3, 13, winnipeg)
        result = apply(StaticOffset(Hour(2)), dt)
        @test result == ZonedDateTime(2016, 3, 13, 3, winnipeg)

        dt = ZonedDateTime(2016, 3, 13, 3, winnipeg)
        result = apply(StaticOffset(Minute(-15)), dt)
        @test result == ZonedDateTime(2016, 3, 13, 1, 45, winnipeg)

        # 23 hour day
        dt = ZonedDateTime(2016, 3, 13, winnipeg)
        result = apply(StaticOffset(Hour(24)), dt)
        @test result == ZonedDateTime(2016, 3, 14, 1, winnipeg)

        dt = ZonedDateTime(2016, 3, 13, winnipeg)
        result = apply(StaticOffset(Day(1)), dt)
        @test result == ZonedDateTime(2016, 3, 14, winnipeg)

        dt = ZonedDateTime(2016, 3, 12, 2, winnipeg)
        @test_throws NonExistentTimeError apply(StaticOffset(Day(1)), dt)       # DNE

        dt = LaxZonedDateTime(dt)
        result = apply(StaticOffset(Day(1)), dt)
        @test result == LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg)    # DNE
    end

    @testset "fall back" begin
        dt = ZonedDateTime(2016, 11, 6, winnipeg)
        result = apply(StaticOffset(Minute(90)), dt)
        @test result == ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1)

        dt = ZonedDateTime(2016, 11, 6, winnipeg)
        result = apply(StaticOffset(Minute(150)), dt)
        @test result == ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 2)

        dt = ZonedDateTime(2016, 11, 6, winnipeg)
        result = apply(StaticOffset(Hour(3)), dt)
        @test result == ZonedDateTime(2016, 11, 6, 2, winnipeg)

        dt = ZonedDateTime(2016, 11, 6, 2, winnipeg)
        result = apply(StaticOffset(Minute(-15)), dt)
        @test result == ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2)

        dt = ZonedDateTime(2016, 11, 6, 2, winnipeg)
        result = apply(StaticOffset(Minute(-75)), dt)
        @test result == ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1)

        # 25 hour day
        dt = ZonedDateTime(2016, 11, 6, winnipeg)
        result = apply(StaticOffset(Hour(24)), dt)
        @test result == ZonedDateTime(2016, 11, 6, 23, winnipeg)

        dt = ZonedDateTime(2016, 11, 6, winnipeg)
        result = apply(StaticOffset(Day(1)), dt)
        @test result == ZonedDateTime(2016, 11, 7, winnipeg)

        dt = ZonedDateTime(2016, 11, 5, 1, winnipeg)
        @test_throws AmbiguousTimeError apply(StaticOffset(Day(1)), dt)         # AMB

        dt = LaxZonedDateTime(dt)
        result = apply(StaticOffset(Day(1)), dt)
        @test result == LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg)    # AMB
    end
end

@testset "LatestOffset" begin
    offset = LatestOffset()
    target = ZonedDateTime(2016, 8, 11, 2, winnipeg)

    latest = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)
    @test apply(offset, target, latest) == latest

    latest = ZonedDateTime(2016, 8, 11, 8, winnipeg)
    @test apply(offset, target, latest) == target
end

@testset "DynamicOffset" begin
    def = DynamicOffset()
    match_hod = DynamicOffset(; fallback=Day(-1))
    match_how = DynamicOffset(; fallback=Week(-1))
    match_hod_tuesday = DynamicOffset(; match=t -> dayofweek(t) == Tuesday)

    sim_now = ZonedDateTime(2016, 8, 11, 1, 30, winnipeg)
    target = ZonedDateTime(2016, 8, 11, 8, winnipeg)                            # Thursday
    latest = ZonedDateTime(2016, 8, 11, 10, winnipeg)

    # Data for target date should be available (accoring to latest), so not much happens.
    @test apply(def, target, latest, sim_now) == apply(match_hod, target, latest, sim_now)
    @test apply(match_hod, target, latest, sim_now) == target
    @test apply(match_how, target, latest, sim_now) == target
    @test apply(match_hod_tuesday, target, latest, sim_now) == target - Day(2)  # Tuesday

    latest = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)

    # Data for target date isn't available, so fall back.
    @test apply(def, target, latest, sim_now) == apply(match_hod, target, latest, sim_now)
    @test apply(match_hod, target, latest, sim_now) == target - Day(1)
    @test apply(match_how, target, latest, sim_now) == target - Week(1)
    @test apply(match_hod_tuesday, target, latest, sim_now) == target - Day(2)  # Tuesday

    latest = ZonedDateTime(2016, 8, 1, 1, 15, winnipeg)

    # Data for target date isn't available, so fall back more.
    @test apply(def, target, latest, sim_now) == apply(match_hod, target, latest, sim_now)
    @test apply(match_hod, target, latest, sim_now) == target - Day(11)
    @test apply(match_how, target, latest, sim_now) == target - Week(2)
    @test apply(match_hod_tuesday, target, latest, sim_now) == target - Day(16) # Tuesday
end

@testset "CustomOffset" begin
    offset_fn(sim_now, target) = (hour(sim_now) ≥ 18) ? sim_now : target
    offset = CustomOffset(offset_fn)

    sim_now_base = ZonedDateTime(2016, 8, 10, 0, 31, 12, winnipeg)
    target = ZonedDateTime(2016, 8, 11, 2, winnipeg)
    for h in 0:17
        sim_now = sim_now_base + Hour(h)
        @test apply(offset, target, nothing, sim_now) == target
    end
    for h in 18:23
        sim_now = sim_now_base + Hour(h)
        @test apply(offset, target, nothing, sim_now) == sim_now
    end
end

@testset "CompoundOffset" begin
    static = StaticOffset(Minute(-30))
    recent = LatestOffset()
    dynamic = DynamicOffset(; fallback=Week(-1))

    # == operator
    @test CompoundOffset([StaticOffset(Minute(0)), dynamic]) == CompoundOffset([dynamic])
    @test CompoundOffset([static, dynamic]) == CompoundOffset([static, dynamic])
    @test CompoundOffset([static, dynamic]) != CompoundOffset([static, recent])

    # + operator
    @test static + dynamic == CompoundOffset([static, dynamic])
    @test recent + dynamic + static == CompoundOffset([recent, dynamic, static])

    # .+ operator
    @test recent .+ [StaticOffset(Hour(-i)) for i in 1:4] == [
        CompoundOffset([recent, StaticOffset(Hour(-1))]),
        CompoundOffset([recent, StaticOffset(Hour(-2))]),
        CompoundOffset([recent, StaticOffset(Hour(-3))]),
        CompoundOffset([recent, StaticOffset(Hour(-4))])
    ]

    sim_now = ZonedDateTime(2016, 8, 11, 1, 30, winnipeg)
    target = ZonedDateTime(2016, 8, 11, 8, winnipeg)
    latest = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)

    compound_result = apply(static + dynamic, target, sim_now, latest)
    chain_result = apply(static, target, sim_now, latest)
    chain_result = apply(dynamic, chain_result, sim_now, latest)
    @test compound_result == chain_result

    compound_result = apply(recent + dynamic + static, target, sim_now, latest)
    chain_result = apply(recent, target, sim_now, latest)
    chain_result = apply(dynamic, chain_result, sim_now, latest)
    chain_result = apply(static, chain_result, sim_now, latest)
    @test compound_result == chain_result
end

@testset "Nullable{ZonedDateTime}" begin
    target = ZonedDateTime(2016, 8, 11, 2, winnipeg)

    nullable_result = apply(StaticOffset(Day(1)), Nullable(target))
    @test get(nullable_result) == apply(StaticOffset(Day(1)), target)

    null_result = apply(StaticOffset(Day(1)), Nullable{ZonedDateTime}())
    @test isnull(null_result)

    latest = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)

    nullable_result = apply(LatestOffset(), Nullable(target), latest)
    @test get(nullable_result) == apply(LatestOffset(), target, latest)

    null_result = apply(LatestOffset(), Nullable{ZonedDateTime}(), latest)
    @test isnull(null_result)
end
