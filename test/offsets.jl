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

        @testset "nested" begin
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

        @testset "nested" begin
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

    @testset "BidTime" begin
        @testset "basic" begin
            offset = BidTime()
            @test offset isa DateOffset

            bid_time = ZonedDateTime(2016, 8, 11, 3, winnipeg)
            sim_now = bid_time - Hour(3)

            target = HourEnding(ZonedDateTime(2016, 8, 11, 8, winnipeg))
            @test offset(OffsetOrigins(target, sim_now, bid_time)) isa AnchoredInterval
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time)

            target = HourEnding(ZonedDateTime(2016, 8, 11, 1, winnipeg))
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time)

            sim_now = ZonedDateTime(2016, 8, 12, 4, winnipeg)
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time)

            bid_time = ZonedDateTime(2016, 8, 12, 5, winnipeg)
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time)
        end

        @testset "nested" begin
            bid_time = ZonedDateTime(2016, 8, 11, 3, 30, winnipeg)
            sim_now = ZonedDateTime(2016, 8, 11, 3, 30, winnipeg) - Day(1)
            offset = StaticOffset(BidTime(), Hour(2))

            target = HE(ZonedDateTime(2016, 8, 11, 5, winnipeg))
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time + Hour(2))

            target = HE(ZonedDateTime(2016, 8, 10, 1, winnipeg))
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time + Hour(2))

            sim_now = ZonedDateTime(2016, 8, 12, 1, 30, winnipeg)
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time + Hour(2))

            bid_time = ZonedDateTime(2016, 8, 12, 7, 30, winnipeg)
            @test offset(OffsetOrigins(target, sim_now, bid_time)) == HourEnding(bid_time + Hour(2))
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

struct CustomOffset <: DateOffset end
(::CustomOffset)(o) = (hour(anchor(o.sim_now)) ≥ 18) ? HE(anchor(o.sim_now)) : o.target

@testset "CustomOffset" begin
    offset = CustomOffset()

    sim_now_base = ZonedDateTime(2016, 8, 10, 0, 31, 12, winnipeg)
    target = HourEnding(ZonedDateTime(2016, 8, 11, 2, winnipeg))
    for h in 0:17
        sim_now = sim_now_base + Hour(h)
        @test offset(OffsetOrigins(target, sim_now)) == target
    end
    for h in 18:23
        sim_now = sim_now_base + Hour(h)
        @test offset(OffsetOrigins(target, sim_now)) == HE(sim_now)
    end
end

@testset "repr/print" begin
    @testset "default printing" begin
        mixed = vcat(
            StaticOffset.(BidTime(), Hour.(-1:3)),
            DynamicOffset(Target(), if_after=BidTime()),
            FloorOffset(SimNow()),
            Target(),
        )

        custom = fill(CustomOffset(), 15)

        @testset "$name" for (name, offsets) in [("mixed", mixed), ("custom", custom)]
            str = repr(offsets)
            @test sprint(print, offsets) == str
            @test sprint(show, offsets) == str

            @test startswith(str, "[$(offsets[1]), $(offsets[2])")
            @test !startswith(str, "[$(offsets[1]), $(offsets[2]), $(offsets[3]), ")

            @test endswith(str, "$(offsets[end-1]), $(offsets[end])]")
            @test !endswith(str, ", $(offsets[end-2]), $(offsets[end-1]), $(offsets[end])]")

            str = repr(offsets, context=:compact=>false)
            @test sprint(print, offsets, context=:compact=>false) == str
            @test sprint(show, offsets, context=:compact=>false) == str

            @test startswith(str, "[$(offsets[1]), $(offsets[2]), $(offsets[3]), ")
            @test all(occursin.(repr.(offsets), str))
            @test endswith(str, ", $(offsets[end-2]), $(offsets[end-1]), $(offsets[end])]")
        end
    end

    static_offsets = StaticOffset.(SimNow(), Hour.(1:8))
    short_offsets = "StaticOffset.(SimNow(), [Hour(1), Hour(2)  …  Hour(7), Hour(8)])"
    long_offsets = "StaticOffset.(SimNow(), $(Hour.(1:8)))"

    @testset "StaticOffset" begin
        str = repr(static_offsets)
        @test sprint(print, static_offsets) == str
        @test sprint(show, static_offsets) == str

        @test str == short_offsets

        str = repr(static_offsets, context=:compact=>false)
        @test sprint(print, static_offsets, context=:compact=>false) == str
        @test sprint(show, static_offsets, context=:compact=>false) == str

        @test str == long_offsets

        # Revert to default printing when origins don't match
        str_mixed = repr(vcat(static_offsets, StaticOffset(Target(), Hour(1))))
        @test startswith(str_mixed, "[$(static_offsets[1]), $(static_offsets[2])")
    end

    @testset "FloorOffset" begin
        offsets = FloorOffset.(static_offsets)

        str = repr(offsets)
        @test sprint(print, offsets) == str
        @test sprint(show, offsets) == str

        @test str == "FloorOffset.($short_offsets, Hour)"

        str = repr(offsets, context=:compact=>false)
        @test sprint(print, offsets, context=:compact=>false) == str
        @test sprint(show, offsets, context=:compact=>false) == str

        @test str == "FloorOffset.($long_offsets, Hour)"

        @testset "period change" begin
            offsets = FloorOffset.([BidTime(), SimNow(), Target()])
            str = repr(offsets)
            @test str == "FloorOffset.([BidTime(), SimNow(), Target()], Hour)"

            offsets = FloorOffset.([BidTime(), SimNow(), Target()], Day)
            str = repr(offsets)
            @test str == "FloorOffset.([BidTime(), SimNow(), Target()], Day)"

            # Revert to default printing when periods don't match
            hour_offset = FloorOffset(SimNow(), Hour)
            day_offset = FloorOffset(SimNow(), Day)
            offsets = repeat([day_offset, hour_offset], inner=10)
            str = repr(offsets)
            @test str == "[$day_offset, $day_offset  …  $hour_offset, $hour_offset]"

            str = repr(offsets, context=:compact=>false)
            @test startswith(str, "[$day_offset, $day_offset, $day_offset")
            @test endswith(str, "$hour_offset, $hour_offset, $hour_offset]")
        end
    end

    @testset "DynamicOffset" begin
        offsets = DynamicOffset.(static_offsets)

        str = repr(offsets)
        @test sprint(print, offsets) == str
        @test sprint(show, offsets) == str

        @test str == "DynamicOffset.($short_offsets, Day(-1), Target(), DateOffsets.always)"

        str = repr(offsets, context=:compact=>false)
        @test sprint(print, offsets, context=:compact=>false) == str
        @test sprint(show, offsets, context=:compact=>false) == str

        @test str == "DynamicOffset.($long_offsets, Day(-1), Target(), DateOffsets.always)"

        @testset "field change" begin
            offsets = DynamicOffset.([BidTime(), SimNow()])
            str = repr(offsets)
            @test str == "DynamicOffset.([BidTime(), SimNow()], Day(-1), Target(), DateOffsets.always)"

            offsets = DynamicOffset.([BidTime(), SimNow()], Hour(-1), SimNow(), isvalid)
            str = repr(offsets)
            @test str == "DynamicOffset.([BidTime(), SimNow()], Hour(-1), SimNow(), isvalid)"

            # Revert to default printing when fields don't match
            hour_offset = DynamicOffset(SimNow(), fallback=Hour(-1))
            day_offset = DynamicOffset(SimNow(), fallback=Day(-1))
            offsets = repeat([day_offset, hour_offset], inner=10)
            str = repr(offsets)
            @test str == "[$day_offset, $day_offset  …  $hour_offset, $hour_offset]"

            str = repr(offsets, context=:compact=>false)
            @test startswith(str, "[$day_offset, $day_offset, $day_offset, ")
            @test endswith(str, ", $hour_offset, $hour_offset, $hour_offset]")
        end
    end
end

@testset "isless" begin
    @test SimNow() < Target() < BidTime()

    @test DynamicOffset(fallback=Day(-1), if_after=SimNow()) < DynamicOffset(fallback=Hour(-1), if_after=SimNow())

    @test StaticOffset(Day(-1)) < StaticOffset(Hour(-1))
    @test StaticOffset(SimNow(), Hour(-1)) < StaticOffset(Target(), Day(-3))

    @test FloorOffset(Target(), Hour) < Target()
    @test FloorOffset(Target(), Day) < FloorOffset(Target(), Hour)

    # isless automatically defined for new offsets
    @test CustomOffset() < BidTime()

    unsorted = vcat(StaticOffset.(BidTime(), Hour.(-1:3)), FloorOffset(SimNow()), Target())
    expected = vcat(FloorOffset(SimNow()), Target(), StaticOffset.(BidTime(), Hour.(-1:3)))
    # The order of offsets doesn't matter too much, but sorting should work
    @test sort(unsorted) == expected

    # Check for https://gitlab.invenia.ca/invenia/DateOffsets.jl/-/issues/46
    isvalid_offset = DynamicOffset(; match=isvalid)
    @test !(isvalid_offset < isvalid_offset)
end
