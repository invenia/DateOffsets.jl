using Missings

winnipeg = tz"America/Winnipeg"

@testset "StaticOffset" begin
    @testset "basic" begin
        dt = ZonedDateTime(2016, 1, 2, 1, winnipeg)

        @testset "ZonedDateTime" begin
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

        @testset "HourEnding" begin
            he = HourEnding(dt)

            result = apply(StaticOffset(Second(0)), he)
            @test result == he

            result = apply(StaticOffset(Minute(-15)), he)
            @test result == HourEnding(ZonedDateTime(2016, 1, 2, 0, 45, winnipeg))

            result = apply(StaticOffset(Hour(6)), he)
            @test result == HourEnding(ZonedDateTime(2016, 1, 2, 7, winnipeg))

            result = apply(StaticOffset(Day(-1)), he)
            @test result == HourEnding(ZonedDateTime(2016, 1, 1, 1, winnipeg))

            result = apply(StaticOffset(Week(2)), he)
            @test result == HourEnding(ZonedDateTime(2016, 1, 16, 1, winnipeg))
        end
    end

    @testset "addition" begin
        dt = ZonedDateTime(2016, 1, 2, 1, winnipeg)

        @testset "ZonedDateTime" begin
            offset = StaticOffset(Second(0))
            @test apply(offset, dt) == offset + dt == dt + offset

            offset = StaticOffset(Minute(-15))
            @test apply(offset, dt) == offset + dt == dt + offset

            offset = StaticOffset(Hour(6))
            @test apply(offset, dt) == offset + dt == dt + offset

            offset = StaticOffset(Day(-1))
            @test apply(offset, dt) == offset + dt == dt + offset

            offset = StaticOffset(Week(2))
            @test apply(offset, dt) == offset + dt == dt + offset
        end

        @testset "HourEnding" begin
            he = HourEnding(dt)

            offset = StaticOffset(Second(0))
            @test apply(offset, he) == offset + he == he + offset

            offset = StaticOffset(Minute(-15))
            @test apply(offset, he) == offset + he == he + offset

            offset = StaticOffset(Hour(6))
            @test apply(offset, he) == offset + he == he + offset

            offset = StaticOffset(Day(-1))
            @test apply(offset, he) == offset + he == he + offset

            offset = StaticOffset(Week(2))
            @test apply(offset, he) == offset + he == he + offset
        end
    end

    @testset "unary negation" begin
        @test -StaticOffset(Minute(15)) == StaticOffset(Minute(-15))
        @test -StaticOffset(Minute(-15)) == StaticOffset(Minute(15))

        dt = ZonedDateTime(2016, 1, 2, 1, winnipeg)

        @testset "ZonedDateTime" begin
            result = apply(StaticOffset(Minute(-15)), dt)
            @test result == ZonedDateTime(2016, 1, 2, 0, 45, winnipeg)

            result = apply(-StaticOffset(Minute(15)), dt)
            @test result == ZonedDateTime(2016, 1, 2, 0, 45, winnipeg)
        end

        @testset "HourEnding" begin
            he = HourEnding(dt)

            result = apply(StaticOffset(Minute(-15)), he)
            @test result == HourEnding(ZonedDateTime(2016, 1, 2, 0, 45, winnipeg))

            result = apply(-StaticOffset(Minute(15)), he)
            @test result == HourEnding(ZonedDateTime(2016, 1, 2, 0, 45, winnipeg))
        end
    end

    @testset "spring forward" begin
        @testset "ZonedDateTime" begin
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

        @testset "HourEnding" begin
            he = HourEnding(ZonedDateTime(2016, 3, 13, 1, winnipeg))
            result = apply(StaticOffset(Minute(90)), he)
            @test result == HourEnding(ZonedDateTime(2016, 3, 13, 3, 30, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 3, 13, winnipeg))
            result = apply(StaticOffset(Hour(2)), he)
            @test result == HourEnding(ZonedDateTime(2016, 3, 13, 3, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 3, 13, 3, winnipeg))
            result = apply(StaticOffset(Minute(-15)), he)
            @test result == HourEnding(ZonedDateTime(2016, 3, 13, 1, 45, winnipeg))

            # 23 hour day
            he = HourEnding(ZonedDateTime(2016, 3, 13, winnipeg))
            result = apply(StaticOffset(Hour(24)), he)
            @test result == HourEnding(ZonedDateTime(2016, 3, 14, 1, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 3, 13, winnipeg))
            result = apply(StaticOffset(Day(1)), he)
            @test result == HourEnding(ZonedDateTime(2016, 3, 14, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 3, 12, 2, winnipeg))
            @test_throws NonExistentTimeError apply(StaticOffset(Day(1)), he)       # DNE

            he = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 3, 12, 2, winnipeg)))
            result = apply(StaticOffset(Day(1)), he)
            @test result === HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg))
        end
    end

    @testset "fall back" begin
        @testset "ZonedDateTime" begin
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

        @testset "HourEnding" begin
            he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
            result = apply(StaticOffset(Minute(90)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 1))

            he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
            result = apply(StaticOffset(Minute(150)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 30, winnipeg, 2))

            he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
            result = apply(StaticOffset(Hour(3)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg))
            result = apply(StaticOffset(Minute(-15)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 2))

            he = HourEnding(ZonedDateTime(2016, 11, 6, 2, winnipeg))
            result = apply(StaticOffset(Minute(-75)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 6, 1, 45, winnipeg, 1))

            # 25 hour day
            he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
            result = apply(StaticOffset(Hour(24)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 6, 23, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 11, 6, winnipeg))
            result = apply(StaticOffset(Day(1)), he)
            @test result == HourEnding(ZonedDateTime(2016, 11, 7, winnipeg))

            he = HourEnding(ZonedDateTime(2016, 11, 5, 1, winnipeg))
            @test_throws AmbiguousTimeError apply(StaticOffset(Day(1)), he)         # AMB

            he = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 11, 5, 1, winnipeg)))
            result = apply(StaticOffset(Day(1)), he)
            @test result === HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg))
        end
    end

    @testset "equality" begin
        @test StaticOffset(Day(1)) == StaticOffset(Day(1))
        @test isequal(StaticOffset(Day(1)), StaticOffset(Day(1)))
        @test hash(StaticOffset(Day(1))) == hash(StaticOffset(Day(1)))
    end

    @testset "show" begin
        @test sprint(show, StaticOffset(Day(-1))) == "StaticOffset(-1 day)"
        @test sprint(show, StaticOffset(Week(2))) == "StaticOffset(2 weeks)"
    end
end

@testset "LatestOffset" begin
    @testset "basic" begin
        offset = LatestOffset()

        @testset "ZonedDateTime" begin
            target = ZonedDateTime(2016, 8, 11, 2, winnipeg)

            content_end = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)
            @test apply(offset, target, content_end) == content_end

            content_end = ZonedDateTime(2016, 8, 11, 8, winnipeg)
            @test apply(offset, target, content_end) == target
        end

        @testset "HourEnding" begin
            target = HourEnding(ZonedDateTime(2016, 8, 11, 2, winnipeg))

            content_end = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)
            @test apply(offset, target, content_end) == HourEnding(content_end)

            content_end = ZonedDateTime(2016, 8, 11, 8, winnipeg)
            @test apply(offset, target, content_end) == target
        end
    end

    @testset "equality" begin
        @test LatestOffset() == LatestOffset()
        @test isequal(LatestOffset(), LatestOffset())
        @test hash(LatestOffset()) == hash(LatestOffset())
    end

    @testset "addition" begin
        @test_throws ArgumentError LatestOffset() + ZonedDateTime(2016, winnipeg)
        @test_throws ArgumentError ZonedDateTime(2016, winnipeg) + LatestOffset()
    end

    @testset "show" begin
        @test sprint(show, LatestOffset()) == "LatestOffset()"
    end
end

@testset "DynamicOffset" begin
    @testset "basic" begin
        default = DynamicOffset()
        match_hod = DynamicOffset(; fallback=Day(-1))
        match_how = DynamicOffset(; fallback=Week(-1))
        match_hod_tuesday = DynamicOffset(; match=t -> dayofweek(t) == Tuesday)

        sim_now = ZonedDateTime(2016, 8, 11, 1, 30, winnipeg)
        target = ZonedDateTime(2016, 8, 11, 8, winnipeg)                    # Thursday

        for f in (x -> x, HourEnding)
            target = f(target)
            content_end = ZonedDateTime(2016, 8, 11, 10, winnipeg)

            # Data for target date should be available (accoring to content_end).
            @test apply(default, target, content_end, sim_now) ==
                apply(match_hod, target, content_end, sim_now)
            @test apply(match_hod, target, content_end, sim_now) == target
            @test apply(match_how, target, content_end, sim_now) == target
            @test apply(match_hod_tuesday, target, content_end, sim_now) == target - Day(2)

            content_end = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)

            # Data for target date aren't available, so fall back.
            @test apply(default, target, content_end, sim_now) ==
                apply(match_hod, target, content_end, sim_now)
            @test apply(match_hod, target, content_end, sim_now) == target - Day(1)
            @test apply(match_how, target, content_end, sim_now) == target - Week(1)
            @test apply(match_hod_tuesday, target, content_end, sim_now) == target - Day(2)

            content_end = ZonedDateTime(2016, 8, 1, 1, 15, winnipeg)

            # Data for target date aren't available, so fall back more.
            @test apply(default, target, content_end, sim_now) ==
                apply(match_hod, target, content_end, sim_now)
            @test apply(match_hod, target, content_end, sim_now) == target - Day(11)
            @test apply(match_how, target, content_end, sim_now) == target - Week(2)
            @test apply(match_hod_tuesday, target, content_end, sim_now) == target - Day(16)
        end
    end

    @testset "addition" begin
        @test_throws ArgumentError DynamicOffset() + ZonedDateTime(2016, winnipeg)
        @test_throws ArgumentError ZonedDateTime(2016, winnipeg) + DynamicOffset()
    end

    @testset "spring forward" begin
        match_hod = DynamicOffset(; fallback=Day(-1))
        sim_now = ZonedDateTime(2016, 3, 14, 1, 30, winnipeg)
        content_end = ZonedDateTime(2016, 3, 14, 1, winnipeg)

        @testset "ZonedDateTime" begin
            target = ZonedDateTime(2016, 3, 14, 2, winnipeg)
            @test_throws NonExistentTimeError apply(match_hod, target, content_end, sim_now)

            target = LaxZonedDateTime(target)
            result = apply(match_hod, target, content_end, sim_now)
            @test result == LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg)
        end

        @testset "HourEnding" begin
            target = HourEnding(ZonedDateTime(2016, 3, 14, 2, winnipeg))
            @test_throws NonExistentTimeError apply(match_hod, target, content_end, sim_now)

            target = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 3, 14, 2, winnipeg)))
            result = apply(match_hod, target, content_end, sim_now)
            @test result != HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg))
            @test result === HourEnding(LaxZonedDateTime(DateTime(2016, 3, 13, 2), winnipeg))
        end
    end

    @testset "fall back" begin
        match_hod = DynamicOffset(; fallback=Day(-1))
        sim_now = ZonedDateTime(2016, 11, 7, 0, 30, winnipeg)
        content_end = ZonedDateTime(2016, 11, 7, winnipeg)

        @testset "ZonedDateTime" begin
            target = ZonedDateTime(2016, 11, 7, 1, winnipeg)
            @test_throws AmbiguousTimeError apply(match_hod, target, content_end, sim_now)

            target = LaxZonedDateTime(target)
            result = apply(match_hod, target, content_end, sim_now)
            @test result == LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg)
        end

        @testset "HourEnding" begin
            target = HourEnding(ZonedDateTime(2016, 11, 7, 1, winnipeg))
            @test_throws AmbiguousTimeError apply(match_hod, target, content_end, sim_now)

            target = HourEnding(LaxZonedDateTime(ZonedDateTime(2016, 11, 7, 1, winnipeg)))
            result = apply(match_hod, target, content_end, sim_now)
            @test result === HourEnding(LaxZonedDateTime(DateTime(2016, 11, 6, 1), winnipeg))
        end
    end

    @testset "equality" begin
        @test DynamicOffset() == DynamicOffset()
        @test isequal(DynamicOffset(), DynamicOffset())
        @test hash(DynamicOffset()) == hash(DynamicOffset())

        match(x) = true
        @test DynamicOffset(; match=match) == DynamicOffset(; match=match)
        @test isequal(DynamicOffset(; match=match), DynamicOffset(; match=match))
        @test hash(DynamicOffset(; match=match)) == hash(DynamicOffset(; match=match))
    end

    @testset "show" begin
        offset = DynamicOffset()
        @test ismatch(r"DynamicOffset\(-1 day, DateOffsets.+\)", sprint(show, offset))

        match_function(x) = true
        offset = DynamicOffset(; fallback=Week(-1), match=match_function)
        @test sprint(show, offset) == "DynamicOffset(-1 week, match_function)"
    end
end

@testset "CustomOffset" begin
    @testset "basic" begin
        @testset "ZonedDateTime" begin
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

        @testset "HourEnding" begin
            offset_fn(sim_now, target) = (hour(sim_now) ≥ 18) ? HE(sim_now) : target
            offset = CustomOffset(offset_fn)

            sim_now_base = ZonedDateTime(2016, 8, 10, 0, 31, 12, winnipeg)
            target = HourEnding(ZonedDateTime(2016, 8, 11, 2, winnipeg))
            for h in 0:17
                sim_now = sim_now_base + Hour(h)
                @test apply(offset, target, nothing, sim_now) == target
            end
            for h in 18:23
                sim_now = sim_now_base + Hour(h)
                @test apply(offset, target, nothing, sim_now) == HE(sim_now)
            end
        end
    end

    @testset "addition" begin
        offset = CustomOffset((x, y) -> x)
        @test_throws ArgumentError offset + ZonedDateTime(2016, winnipeg)
        @test_throws ArgumentError ZonedDateTime(2016, winnipeg) + offset
    end

    @testset "equality" begin
        match(x, y) = x != y
        @test CustomOffset(match) == CustomOffset(match)
        @test isequal(CustomOffset(match), CustomOffset(match))
        @test hash(CustomOffset(match)) == hash(CustomOffset(match))
    end

    @testset "show" begin
        custom_function(x, y) = x
        @test sprint(show, CustomOffset(custom_function)) == "CustomOffset(custom_function)"
    end
end

@testset "CompoundOffset" begin
    @testset "basic" begin
        static = StaticOffset(Minute(-30))
        recent = LatestOffset()
        dynamic = DynamicOffset(; fallback=Week(-1))

        # vararg constructor
        @test CompoundOffset(static, recent) == CompoundOffset([static, recent])
        @test CompoundOffset(recent, dynamic) == CompoundOffset([recent, dynamic])

        # == operator
        @test CompoundOffset([StaticOffset(Minute(0)),dynamic]) == CompoundOffset([dynamic])
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

        # - operator
        @test dynamic - static == CompoundOffset([dynamic, -static])
        @test recent + dynamic - static == CompoundOffset([recent, dynamic, -static])

        # .- operator
        @test recent .- [StaticOffset(Hour(i)) for i in 1:4] == [
            CompoundOffset([recent, StaticOffset(Hour(-1))]),
            CompoundOffset([recent, StaticOffset(Hour(-2))]),
            CompoundOffset([recent, StaticOffset(Hour(-3))]),
            CompoundOffset([recent, StaticOffset(Hour(-4))])
        ]

        sim_now = ZonedDateTime(2016, 8, 11, 1, 30, winnipeg)
        target = ZonedDateTime(2016, 8, 11, 8, winnipeg)
        content_end = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)

        for f in (x -> x, HourEnding)
            target = f(target)
            compound_result = apply(static + dynamic, target, sim_now, content_end)
            chain_result = apply(static, target, sim_now, content_end)
            chain_result = apply(dynamic, chain_result, sim_now, content_end)
            @test compound_result == chain_result

            compound_result = apply(recent + dynamic + static, target, sim_now, content_end)
            chain_result = apply(recent, target, sim_now, content_end)
            chain_result = apply(dynamic, chain_result, sim_now, content_end)
            chain_result = apply(static, chain_result, sim_now, content_end)
            @test compound_result == chain_result
        end
    end

    @testset "addition" begin
        offset = LatestOffset() + StaticOffset(Day(-2))
        @test_throws ArgumentError offset + ZonedDateTime(2016, winnipeg)
        @test_throws ArgumentError ZonedDateTime(2016, winnipeg) + offset
    end

    @testset "equality" begin
        o1 = StaticOffset(Day(1)) + LatestOffset()
        o2 = StaticOffset(Day(1)) + LatestOffset()
        @test o1 == o2
        @test isequal(o1, o2)
        @test hash(o1) == hash(o2)

        # Order matters!
        o3 = LatestOffset() + StaticOffset(Day(1))
        @test o1 != o3
        @test !isequal(o1, o3)
        @test hash(o1) != hash(o3)
    end

    @testset "show" begin
        offset = StaticOffset(Day(1)) + LatestOffset()
        @test sprint(show, offset) == "CompoundOffset(StaticOffset(1 day), LatestOffset())"

        offset = LatestOffset() + StaticOffset(Day(1))
        @test sprint(show, offset) == "CompoundOffset(LatestOffset(), StaticOffset(1 day))"

        offset = LatestOffset() + StaticOffset(Day(0))
        @test sprint(show, offset) == "CompoundOffset(LatestOffset())"
    end
end

@testset "missing target" begin
    target_date = ZonedDateTime(2016, 8, 11, 2, winnipeg)
    content_end = ZonedDateTime(2016, 8, 11, 1, 15, winnipeg)

    result = apply(StaticOffset(Day(1)), missing)
    @test ismissing(result)

    result = apply(LatestOffset(), missing, content_end)
    @test ismissing(result)

    for t in (target_date, HourEnding(target_date))
        result = apply.(LatestOffset(), [missing, t, missing], content_end)
        @test isequal(result, [missing, apply(LatestOffset(), t, content_end), missing])
    end
end
