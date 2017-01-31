import Mocking
Mocking.enable()

using Offsets
using TimeZones
using LaxZonedDateTimes
#using DataSources
#using Intervals
#using NullableArrays
using Base.Test
using Base.Dates

@testset "Offsets" begin
    include("horizons.jl")
    include("sourceoffsets.jl")
end

#=
Repurpose "observation_dates" basic tests to be tests with static offset 0 (in part)?

@testset "observation_dates" begin
    @testset "basic" begin
        sim_now = ZonedDateTime(2016, 8, 3, 0, 10, winnipeg)
        target_dates = horizon_hourly(sim_now, Hour(2):Hour(4))
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))

        @test isa(o, NullableArray)

        @test isequal(o, NullableArray([
            ZonedDateTime(2016, 8, 1, 3, winnipeg),
            ZonedDateTime(2016, 8, 1, 4, winnipeg),
            ZonedDateTime(2016, 8, 1, 5, winnipeg),
            ZonedDateTime(2016, 8, 2, 3, winnipeg),
            ZonedDateTime(2016, 8, 2, 4, winnipeg),
            ZonedDateTime(2016, 8, 2, 5, winnipeg),
            ZonedDateTime(2016, 8, 3, 3, winnipeg),
            ZonedDateTime(2016, 8, 3, 4, winnipeg),
            ZonedDateTime(2016, 8, 3, 5, winnipeg)
        ]))
        @test s == [
            ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 3, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 3, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 3, 0, 10, winnipeg)
        ]

        o, s = observation_dates(target_dates, sim_now, Day(1), Day(1) .. Day(2), Day(4) .. Day(5))
        @test isequal(o, NullableArray([
            ZonedDateTime(2016, 7, 29, 3, winnipeg),
            ZonedDateTime(2016, 7, 29, 4, winnipeg),
            ZonedDateTime(2016, 7, 29, 5, winnipeg),
            ZonedDateTime(2016, 7, 30, 3, winnipeg),
            ZonedDateTime(2016, 7, 30, 4, winnipeg),
            ZonedDateTime(2016, 7, 30, 5, winnipeg),
            ZonedDateTime(2016, 8, 1, 3, winnipeg),
            ZonedDateTime(2016, 8, 1, 4, winnipeg),
            ZonedDateTime(2016, 8, 1, 5, winnipeg),
            ZonedDateTime(2016, 8, 2, 3, winnipeg),
            ZonedDateTime(2016, 8, 2, 4, winnipeg),
            ZonedDateTime(2016, 8, 2, 5, winnipeg)
        ]))
        @test s == [
            ZonedDateTime(2016, 7, 29, 0, 10, winnipeg),
            ZonedDateTime(2016, 7, 29, 0, 10, winnipeg),
            ZonedDateTime(2016, 7, 29, 0, 10, winnipeg),
            ZonedDateTime(2016, 7, 30, 0, 10, winnipeg),
            ZonedDateTime(2016, 7, 30, 0, 10, winnipeg),
            ZonedDateTime(2016, 7, 30, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
            ZonedDateTime(2016, 8, 2, 0, 10, winnipeg)
        ]

        target_dates = horizon_daily(sim_now)
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 8, 2, 1, winnipeg):Hour(1):ZonedDateTime(2016, 8, 3, winnipeg),
                ZonedDateTime(2016, 8, 3, 1, winnipeg):Hour(1):ZonedDateTime(2016, 8, 4, winnipeg),
                ZonedDateTime(2016, 8, 4, 1, winnipeg):Hour(1):ZonedDateTime(2016, 8, 5, winnipeg),
            )
        ))
        @test s == cat(
            1,
            repmat([sim_now - Day(2)], 24),
            repmat([sim_now - Day(1)], 24),
            repmat([sim_now], 24)
        )
    end

    @testset "spring forward" begin
        # Assumes current relationship between sim_now and target_dates remains the same.
        sim_now = ZonedDateTime(2016, 3, 13, 0, 10, winnipeg)
        target_dates = horizon_daily(sim_now)
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 3, 12, winnipeg):Hour(1):ZonedDateTime(2016, 3, 12, 23, winnipeg),
                ZonedDateTime(2016, 3, 13, winnipeg):Hour(1):ZonedDateTime(2016, 3, 14, winnipeg),
                ZonedDateTime(2016, 3, 14, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 15, winnipeg)
            )
        ))
        @test s == cat(
            1,
            repmat([sim_now - Day(2)], 24),
            repmat([sim_now - Day(1)], 24),
            repmat([sim_now], 24)
        )

        # Assumes that the number of target_dates remains the same.
        target_dates = horizon_daily(sim_now; days_ahead=Day(0))
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 3, 11, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 11, 23, winnipeg),
                ZonedDateTime(2016, 3, 12, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 12, 23, winnipeg),
                ZonedDateTime(2016, 3, 13, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 14, winnipeg)
            )
        ))
        @test s == cat(
            1,
            repmat([sim_now - Day(2)], 23),
            repmat([sim_now - Day(1)], 23),
            repmat([sim_now], 23)
        )

        # Test sim_nows that would hit invalid/missing times. If we go back by a number of hours and
        # hit a missing time, we simply slide past it to the next hour.
        sim_now = ZonedDateTime(2016, 3, 13, 3, 10, winnipeg)
        target_dates = horizon_hourly(sim_now, Hour(1):Hour(1):Hour(3))
        o, s = observation_dates(target_dates, sim_now, Hour(1), Hour(3))
        @test isequal(s,
            [
                ZonedDateTime(2016, 3, 12, 23, 10, winnipeg),
                ZonedDateTime(2016, 3, 12, 23, 10, winnipeg),
                ZonedDateTime(2016, 3, 12, 23, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 0, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 0, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 0, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 1, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 1, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 1, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 3, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 3, 10, winnipeg),
                ZonedDateTime(2016, 3, 13, 3, 10, winnipeg)
            ]
        )
        @test isequal(o, NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 3, 13, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, 4, winnipeg),
                ZonedDateTime(2016, 3, 13, 3, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, 5, winnipeg),
                ZonedDateTime(2016, 3, 13, 4, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, 6, winnipeg),
                ZonedDateTime(2016, 3, 13, 5, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, 7, winnipeg)
            )
        ))

        # Test sim_nows that would hit invalid/missing times. If we go back by a number of
        # days and hit a missing time, the corresponding set of observations will be omitted
        # as well.
        sim_now = ZonedDateTime(2016, 3, 14, 2, 10, winnipeg)
        target_dates = horizon_hourly(sim_now, Hour(1):Hour(1):Hour(3))
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            [
                ZonedDateTime(2016, 3, 12, 4, winnipeg),
                ZonedDateTime(2016, 3, 12, 5, winnipeg),
                ZonedDateTime(2016, 3, 12, 6, winnipeg),
                ZonedDateTime(2016, 3, 14, 4, winnipeg),
                ZonedDateTime(2016, 3, 14, 5, winnipeg),
                ZonedDateTime(2016, 3, 14, 6, winnipeg)
            ]
        ))
        @test isequal(s,
            [
                ZonedDateTime(2016, 3, 12, 2, 10, winnipeg),
                ZonedDateTime(2016, 3, 12, 2, 10, winnipeg),
                ZonedDateTime(2016, 3, 12, 2, 10, winnipeg),
                ZonedDateTime(2016, 3, 14, 2, 10, winnipeg),
                ZonedDateTime(2016, 3, 14, 2, 10, winnipeg),
                ZonedDateTime(2016, 3, 14, 2, 10, winnipeg)
            ]
        )
    end

    @testset "fall back" begin
        # Assumes current relationship between sim_now and target_dates remains the same.
        sim_now = ZonedDateTime(2016, 11, 6, 0, 10, winnipeg)
        target_dates = horizon_daily(sim_now)
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 11, 5, 2, winnipeg):Hour(1):ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
                ZonedDateTime(2016, 11, 6, 1, winnipeg, 2):Hour(1):ZonedDateTime(2016, 11, 7, winnipeg),
                ZonedDateTime(2016, 11, 7, 1, winnipeg):Hour(1):ZonedDateTime(2016, 11, 8, winnipeg)
            )
        ))
        @test s == cat(
            1,
            repmat([sim_now - Day(2)], 24),
            repmat([sim_now - Day(1)], 24),
            repmat([sim_now], 24)
        )

        # Assumes that the number of target_dates remains the same.
        target_dates = horizon_daily(sim_now; days_ahead=Day(0))
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 11, 4, 1, winnipeg):Hour(1):ZonedDateTime(2016, 11, 5, 1, winnipeg),
                ZonedDateTime(2016, 11, 5, 1, winnipeg):Hour(1):ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
                ZonedDateTime(2016, 11, 6, 1, winnipeg, 1):Hour(1):ZonedDateTime(2016, 11, 7, winnipeg)
            )
        ))
        @test s == cat(
            1,
            repmat([sim_now - Day(2)], 25),
            repmat([sim_now - Day(1)], 25),
            repmat([sim_now], 25)
        )

        # Test sim_nows that would hit ambiguous times. If we go back by a number of days
        # and hit a missing time, we expect to see the later of the possible times selected.
        sim_now = ZonedDateTime(2016, 11, 7, 1, 10, winnipeg)
        target_dates = horizon_hourly(sim_now, Hour(1):Hour(1):Hour(3))
        o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
        @test isequal(o, NullableArray(
            [
                ZonedDateTime(2016, 11, 5, 3, winnipeg),
                ZonedDateTime(2016, 11, 5, 4, winnipeg),
                ZonedDateTime(2016, 11, 5, 5, winnipeg),
                ZonedDateTime(2016, 11, 6, 3, winnipeg),
                ZonedDateTime(2016, 11, 6, 4, winnipeg),
                ZonedDateTime(2016, 11, 6, 5, winnipeg),
                ZonedDateTime(2016, 11, 7, 3, winnipeg),
                ZonedDateTime(2016, 11, 7, 4, winnipeg),
                ZonedDateTime(2016, 11, 7, 5, winnipeg)
            ]
        ))
        @test isequal(s,
            [
                ZonedDateTime(2016, 11, 5, 1, 10, winnipeg),
                ZonedDateTime(2016, 11, 5, 1, 10, winnipeg),
                ZonedDateTime(2016, 11, 5, 1, 10, winnipeg),
                ZonedDateTime(2016, 11, 6, 1, 10, winnipeg, 2),
                ZonedDateTime(2016, 11, 6, 1, 10, winnipeg, 2),
                ZonedDateTime(2016, 11, 6, 1, 10, winnipeg, 2),
                ZonedDateTime(2016, 11, 7, 1, 10, winnipeg),
                ZonedDateTime(2016, 11, 7, 1, 10, winnipeg),
                ZonedDateTime(2016, 11, 7, 1, 10, winnipeg)
            ]
        )
    end
end

@testset "static_offset" begin
    # cat(2, X) is used in several cases to convert a vector into a 2D array with 1 column.
    @testset "basic" begin
        td0 = NullableArray(ZonedDateTime(2016, 10, 1, 1, winnipeg):Hour(1):ZonedDateTime(2016, 10, 2, winnipeg))
        td1 = static_offset(td0, Day(0))    # Should be the same.

        @test isa(td1, NullableArray)

        @test isequal(cat(2, td0), td1)

        td2 = static_offset(td1, Day(1))
        expected = NullableArray(ZonedDateTime(2016, 10, 2, 1, winnipeg):Hour(1):ZonedDateTime(2016, 10, 3, winnipeg))
        @test isequal(td2, cat(2, expected))

        td3 = static_offset(td1, -Day(1), -Hour(12))
        expected = NullableArray(
            cat(
                2,
                ZonedDateTime(2016, 9, 30, 1, winnipeg):Hour(1):ZonedDateTime(2016, 10, 1, winnipeg),
                ZonedDateTime(2016, 9, 30, 13, winnipeg):Hour(1):ZonedDateTime(2016, 10, 1, 12, winnipeg)
            )
        )
        @test isequal(td3, expected)

        td4 = static_offset(td3, Day(0), Day(1), Week(1))
        expected = cat(
            2,
            td3,    # 2 columns
            td1,    # 1 column
            NullableArray(ZonedDateTime(2016, 10, 1, 13, winnipeg):Hour(1):ZonedDateTime(2016, 10, 2, 12, winnipeg)),
            NullableArray(ZonedDateTime(2016, 10, 7, 1, winnipeg):Hour(1):ZonedDateTime(2016, 10, 8, winnipeg)),
            NullableArray(ZonedDateTime(2016, 10, 7, 13, winnipeg):Hour(1):ZonedDateTime(2016, 10, 8, 12, winnipeg))
        )
        @test isequal(td4, expected)
    end

    @testset "fall back" begin
    end
end

# Since latest_target is tested in DataSources.jl, mock up the latest target information
# used by dynamic_offset to make tests easier to follow.
patch = @patch function latest_target(table::Table, sim_now::ZonedDateTime)
    return floor(sim_now + ((table.name == :future) ? Day(8) : Minute(-5)), Minute(30))
end

apply(patch) do
    @testset "recent_offset" begin
        sim_now = ZonedDateTime(2016, 10, 2, 7, 37, winnipeg)
        t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
        o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
        o = static_offset(o, -Hour(2), Hour(2))

        r = recent_offset(o, s, Table(:past))

        @test isa(r, NullableArray)

        expected = NullableArray(
            [
                # First three rows are "training" observations. (We specified a one-hour
                # interval for the observations.)
                ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 2, 6, 30, winnipeg);
                ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 6, 30, winnipeg);
                ZonedDateTime(2016, 10, 2, 6, 30, winnipeg) ZonedDateTime(2016, 10, 2, 6, 30, winnipeg)
                # Remaining three rows are "forecast" observations. The offsets for each
                # set of observations should be the same, and the dynamic offsets should
                # use the corresponding sim_now. Things are mocked up such that data is
                # available as of "five minutes ago", meaning that most of the "recent"
                # data will be stale, and all will be from prior to our forecast target.
                ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 7, 30, winnipeg);
                ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 7, 30, winnipeg);
                ZonedDateTime(2016, 10, 2, 7, 30, winnipeg) ZonedDateTime(2016, 10, 2, 7, 30, winnipeg)
            ]
        )
        @test isequal(r, expected)

        r = recent_offset(o, s, Table(:future))
        expected = NullableArray(
            [
                # All data are available, as data is available for the (fake) future
                # table far in advance (presumably it's a table of forecasts).
                ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 2, 9, winnipeg);
                ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                ZonedDateTime(2016, 10, 2, 8, winnipeg) ZonedDateTime(2016, 10, 2, 12, winnipeg)
            ]
        )
        @test isequal(r, expected)
    end

    @testset "dynamic_offset" begin
        @testset "no match function" begin
            sim_now = ZonedDateTime(2016, 10, 2, 7, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            # Step must be negative (otherwise it would go on forever).
            @test_throws ArgumentError dynamic_offset(o, s, Hour(1), Table(:past))

            r = dynamic_offset(o, s, Hour(-1), Table(:past))

            @test isa(r, NullableArray)

            expected = NullableArray(
                [
                    # When we don't supply a match function, dynamic_offset is basically
                    # equivalent to recent_offset (the only difference is that when a date
                    # isn't "available" it steps back by the specified step, in this case 1
                    # hour, until data for the resulting date is "available", while
                    # recent_offset will just use the latest available date itself).
                    ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 2, 6, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 6, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 6, winnipeg)
                    # Remaining three rows are "forecast" observations. The offsets for each
                    # set of observations should be the same, and the dynamic offsets should
                    # use the corresponding sim_now. Things are mocked up such that data is
                    # available as of "five minutes ago", meaning that most of the "recent"
                    # data will be stale, and all will be from prior to our forecast target.
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 7, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 7, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 7, winnipeg)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset(o, s, Hour(-1), Table(:future))
            expected = NullableArray(
                [
                    # All data are available, as data is available for the (fake) future
                    # table far in advance (presumably it's a table of forecasts).
                    ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 2, 9, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 8, winnipeg) ZonedDateTime(2016, 10, 2, 12, winnipeg)
                ]
            )
            @test isequal(r, expected)
        end

        @testset "with match function" begin
            sim_now = ZonedDateTime(2016, 10, 4, 0, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))

            # This match function only accepts DateTimes that have an even hour of day and
            # even day of week. (2016-10-04 was a Tuesday, which is day of week 2.)
            match_even(d) = (hour(d) % 2 == 0) && (dayofweek(d) % 2 == 0)

            r = dynamic_offset(o, s, Hour(-1), Table(:past); match=match_even)

            @test isa(r, NullableArray)

            expected = NullableArray(
                [
                    ZonedDateTime(2016, 10, 1, 22, winnipeg),   # No match: 2016-10-03 23:00
                    ZonedDateTime(2016, 10, 1, 22, winnipeg),   # No match: 2016-10-03 23:00
                    ZonedDateTime(2016, 10, 1, 22, winnipeg),   # No match: 2016-10-03 23:00
                    ZonedDateTime(2016, 10, 4, 0, winnipeg),
                    ZonedDateTime(2016, 10, 4, 0, winnipeg),    # No match: 2016-10-04 00:00
                    ZonedDateTime(2016, 10, 4, 0, winnipeg)     # No match: 2016-10-04 00:00
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset(o, s, Hour(-1), Table(:future); match=match_even)
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 10, 4, 0, winnipeg),
                    ZonedDateTime(2016, 10, 4, 0, winnipeg),    # No match: 2016-10-04 01:00
                    ZonedDateTime(2016, 10, 4, 2, winnipeg),
                    ZonedDateTime(2016, 10, 4, 0, winnipeg),    # No match: 2016-10-04 01:00
                    ZonedDateTime(2016, 10, 4, 2, winnipeg),
                    ZonedDateTime(2016, 10, 4, 2, winnipeg)     # No match: 2016-10-04 03:00
                ]
            )
            @test isequal(r, expected)
        end

        @testset "spring forward" begin
            sim_now = ZonedDateTime(2016, 3, 14, 2, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))

            # This match function only accepts DateTimes that have hour of day 2.
            match_two(d) = hour(d) == 2

            r = dynamic_offset(o, s, Hour(-1), Table(:past); match=match_two)
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 3, 12, 2, winnipeg),
                    ZonedDateTime(2016, 3, 12, 2, winnipeg),
                    ZonedDateTime(2016, 3, 12, 2, winnipeg),
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),
                    ZonedDateTime(2016, 3, 14, 2, winnipeg)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset(o, s, Hour(-1), Table(:future); match=match_two)
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),    # No match: 2016-03-14 03:00
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),    # No match: 2016-03-14 04:00
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),    # No match: 2016-03-14 03:00
                    ZonedDateTime(2016, 3, 14, 2, winnipeg),    # No match: 2016-03-14 04:00
                    ZonedDateTime(2016, 3, 14, 2, winnipeg)     # No match: 2016-03-14 05:00
                ]
            )
            @test isequal(r, expected)
        end

        @testset "fall back" begin
            sim_now = ZonedDateTime(2016, 11, 6, 2, 4, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))

            # This match function only accepts DateTimes that have hour of day equal to 1.
            match_one(d) = hour(d) == 1

            r = dynamic_offset(o, s, Hour(-1), Table(:past); match=match_one)
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2),
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2),
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset(o, s, Hour(-1), Table(:future); match=match_one)
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2), # No match: 2016-11-06 02:00
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2), # No match: 2016-11-06 03:00
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2), # No match: 2016-11-06 04:00
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2), # No match: 2016-11-06 03:00
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2), # No match: 2016-11-06 04:00
                    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2)  # No match: 2016-11-06 05:00
                ]
            )
            @test isequal(r, expected)
        end
    end

    @testset "dynamic_offset_hourofday" begin
        @testset "basic" begin
            sim_now = ZonedDateTime(2016, 10, 2, 7, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            r = dynamic_offset_hourofday(o, s, Table(:past))

            @test isa(r, NullableArray)

            expected = NullableArray(
                [
                    ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 1, 9, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 1, 10, winnipeg);
                    ZonedDateTime(2016, 10, 1, 7, winnipeg) ZonedDateTime(2016, 10, 1, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 1, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 1, 11, winnipeg);
                    ZonedDateTime(2016, 10, 1, 8, winnipeg) ZonedDateTime(2016, 10, 1, 12, winnipeg)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset_hourofday(o, s, Table(:future))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 2, 9, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 8, winnipeg) ZonedDateTime(2016, 10, 2, 12, winnipeg)
                ]
            )
            @test isequal(r, expected)
        end

        @testset "spring forward" begin
            sim_now = ZonedDateTime(2016, 3, 13, 22, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            r = dynamic_offset_hourofday(o, s, Table(:past))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 3, 13, 20, winnipeg) ZonedDateTime(2016, 3, 13, 0, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 13, 1, winnipeg);
                    ZonedDateTime(2016, 3, 12, 22, winnipeg) ZonedDateTime(2016, 3, 12, 2, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 13, 1, winnipeg);
                    ZonedDateTime(2016, 3, 13, 22, winnipeg) ZonedDateTime(2016, 3, 12, 2, winnipeg);
                    ZonedDateTime(2016, 3, 12, 23, winnipeg) ZonedDateTime(2016, 3, 13, 3, winnipeg)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset_hourofday(o, s, Table(:future))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 3, 13, 20, winnipeg) ZonedDateTime(2016, 3, 14, 0, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 14, 1, winnipeg);
                    ZonedDateTime(2016, 3, 13, 22, winnipeg) ZonedDateTime(2016, 3, 14, 2, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 14, 1, winnipeg);
                    ZonedDateTime(2016, 3, 13, 22, winnipeg) ZonedDateTime(2016, 3, 14, 2, winnipeg);
                    ZonedDateTime(2016, 3, 13, 23, winnipeg) ZonedDateTime(2016, 3, 14, 3, winnipeg)
                ]
            )
            @test isequal(r, expected)
        end

        @testset "fall back" begin
            sim_now = ZonedDateTime(2016, 11, 6, 22, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            r = dynamic_offset_hourofday(o, s, Table(:past))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 11, 6, 20, winnipeg) ZonedDateTime(2016, 11, 6, 0, winnipeg);
                    ZonedDateTime(2016, 11, 6, 21, winnipeg) ZonedDateTime(2016, 11, 6, 1, winnipeg, 2);
                    ZonedDateTime(2016, 11, 5, 22, winnipeg) ZonedDateTime(2016, 11, 6, 2, winnipeg);
                    ZonedDateTime(2016, 11, 6, 21, winnipeg) ZonedDateTime(2016, 11, 6, 1, winnipeg, 2);
                    ZonedDateTime(2016, 11, 6, 22, winnipeg) ZonedDateTime(2016, 11, 6, 2, winnipeg);
                    ZonedDateTime(2016, 11, 5, 23, winnipeg) ZonedDateTime(2016, 11, 6, 3, winnipeg);
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset_hourofday(o, s, Table(:future))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 11, 6, 20, winnipeg) ZonedDateTime(2016, 11, 7, 0, winnipeg);
                    ZonedDateTime(2016, 11, 6, 21, winnipeg) ZonedDateTime(2016, 11, 7, 1, winnipeg);
                    ZonedDateTime(2016, 11, 6, 22, winnipeg) ZonedDateTime(2016, 11, 7, 2, winnipeg);
                    ZonedDateTime(2016, 11, 6, 21, winnipeg) ZonedDateTime(2016, 11, 7, 1, winnipeg);
                    ZonedDateTime(2016, 11, 6, 22, winnipeg) ZonedDateTime(2016, 11, 7, 2, winnipeg);
                    ZonedDateTime(2016, 11, 6, 23, winnipeg) ZonedDateTime(2016, 11, 7, 3, winnipeg);
                ]
            )
            @test isequal(r, expected)
        end
    end

    @testset "dynamic_offset_hourofweek" begin
        @testset "basic" begin
            sim_now = ZonedDateTime(2016, 10, 2, 7, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            r = dynamic_offset_hourofweek(o, s, Table(:past))

            @test isa(r, NullableArray)

            expected = NullableArray(
                [
                    ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 9, 25, 9, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 9, 25, 10, winnipeg);
                    ZonedDateTime(2016, 9, 25, 7, winnipeg) ZonedDateTime(2016, 9, 25, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 9, 25, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 9, 25, 11, winnipeg);
                    ZonedDateTime(2016, 9, 25, 8, winnipeg) ZonedDateTime(2016, 9, 25, 12, winnipeg)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset_hourofweek(o, s, Table(:future))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 10, 2, 5, winnipeg) ZonedDateTime(2016, 10, 2, 9, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 6, winnipeg) ZonedDateTime(2016, 10, 2, 10, winnipeg);
                    ZonedDateTime(2016, 10, 2, 7, winnipeg) ZonedDateTime(2016, 10, 2, 11, winnipeg);
                    ZonedDateTime(2016, 10, 2, 8, winnipeg) ZonedDateTime(2016, 10, 2, 12, winnipeg)
                ]
            )
            @test isequal(r, expected)
        end

        @testset "spring forward" begin
            sim_now = ZonedDateTime(2016, 3, 13, 22, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            r = dynamic_offset_hourofweek(o, s, Table(:past))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 3, 13, 20, winnipeg) ZonedDateTime(2016, 3, 7, 0, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 7, 1, winnipeg);
                    ZonedDateTime(2016, 3, 6, 22, winnipeg) ZonedDateTime(2016, 3, 7, 2, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 7, 1, winnipeg);
                    ZonedDateTime(2016, 3, 13, 22, winnipeg) ZonedDateTime(2016, 3, 7, 2, winnipeg);
                    ZonedDateTime(2016, 3, 6, 23, winnipeg) ZonedDateTime(2016, 3, 7, 3, winnipeg)
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset_hourofweek(o, s, Table(:future))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 3, 13, 20, winnipeg) ZonedDateTime(2016, 3, 14, 0, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 14, 1, winnipeg);
                    ZonedDateTime(2016, 3, 13, 22, winnipeg) ZonedDateTime(2016, 3, 14, 2, winnipeg);
                    ZonedDateTime(2016, 3, 13, 21, winnipeg) ZonedDateTime(2016, 3, 14, 1, winnipeg);
                    ZonedDateTime(2016, 3, 13, 22, winnipeg) ZonedDateTime(2016, 3, 14, 2, winnipeg);
                    ZonedDateTime(2016, 3, 13, 23, winnipeg) ZonedDateTime(2016, 3, 14, 3, winnipeg)
                ]
            )
            @test isequal(r, expected)
        end

        @testset "fall back" begin
            sim_now = ZonedDateTime(2016, 11, 12, 22, 37, winnipeg)
            t = horizon_hourly(sim_now, Hour(0):Hour(1):Hour(2))
            o, s = observation_dates(t, sim_now, Hour(1), Hour(0) .. Hour(1))
            o = static_offset(o, -Hour(2), Hour(2))

            r = dynamic_offset_hourofweek(o, s, Table(:past))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 11, 12, 20, winnipeg) ZonedDateTime(2016, 11, 6, 0, winnipeg);
                    ZonedDateTime(2016, 11, 12, 21, winnipeg) ZonedDateTime(2016, 11, 6, 1, winnipeg, 2);
                    ZonedDateTime(2016, 11, 5, 22, winnipeg) ZonedDateTime(2016, 11, 6, 2, winnipeg);
                    ZonedDateTime(2016, 11, 12, 21, winnipeg) ZonedDateTime(2016, 11, 6, 1, winnipeg, 2);
                    ZonedDateTime(2016, 11, 12, 22, winnipeg) ZonedDateTime(2016, 11, 6, 2, winnipeg);
                    ZonedDateTime(2016, 11, 5, 23, winnipeg) ZonedDateTime(2016, 11, 6, 3, winnipeg);
                ]
            )
            @test isequal(r, expected)

            r = dynamic_offset_hourofweek(o, s, Table(:future))
            expected = NullableArray(
                [
                    ZonedDateTime(2016, 11, 12, 20, winnipeg) ZonedDateTime(2016, 11, 13, 0, winnipeg);
                    ZonedDateTime(2016, 11, 12, 21, winnipeg) ZonedDateTime(2016, 11, 13, 1, winnipeg);
                    ZonedDateTime(2016, 11, 12, 22, winnipeg) ZonedDateTime(2016, 11, 13, 2, winnipeg);
                    ZonedDateTime(2016, 11, 12, 21, winnipeg) ZonedDateTime(2016, 11, 13, 1, winnipeg);
                    ZonedDateTime(2016, 11, 12, 22, winnipeg) ZonedDateTime(2016, 11, 13, 2, winnipeg);
                    ZonedDateTime(2016, 11, 12, 23, winnipeg) ZonedDateTime(2016, 11, 13, 3, winnipeg);
                ]
            )
            @test isequal(r, expected)
        end
    end
end
=#
