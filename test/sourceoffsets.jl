winnipeg = TimeZone("America/Winnipeg")

@testset "StaticOffset" begin
    @testset "basic" begin
        dt = ZonedDateTime(2016, 1, 2, 1, winnipeg)
        offsets = [
            StaticOffset(Second(0)),
            StaticOffset(Minute(-15)),
            StaticOffset(Hour(6)),
            StaticOffset(Day(-1)),
            StaticOffset(Week(2))
        ]
        results = []

        push!(results, apply(offsets[1], dt))
        @test results[1] == dt

        push!(results, apply(offsets[2], dt))
        @test results[2] == ZonedDateTime(2016, 1, 2, 0, 45, winnipeg)

        push!(results, apply(offsets[3], dt))
        @test results[3] == ZonedDateTime(2016, 1, 2, 7, winnipeg)

        push!(results, apply(offsets[4], dt))
        @test results[4] == ZonedDateTime(2016, 1, 1, 1, winnipeg)

        push!(results, apply(offsets[5], dt))
        @test results[5] == ZonedDateTime(2016, 1, 16, 1, winnipeg)
    end

    #=
    @testset "spring forward" begin
        offsets = [
            StaticOffset(Minute(90)),
            StaticOffset(
        dt = ZonedDateTime(2016, 3, 13, 1, winnipeg)
        results = []

        push!(results, apply(offsets[1], dt))
        @test results[1] == dt
    end

    @testset "fall back" begin
    end
    =#
end



#=
TODO Tests:
when zoneddatetimes are passed in, things will throw errors
when laxzoneddatetimes are passed in, things will not throw errors
=#



@testset "observations" begin
    @testset "basic" begin
    end

    @testset "spring forward" begin
        #= Static Offsets
        td1 = NullableArray(ZonedDateTime(2016, 3, 12, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, winnipeg))
        td2 = static_offset(td1, Hour(2), Hour(24), Day(1))
        # Note that 2016-03-12 02:00 + 24 hours yields 2016-03-13 03:00 (because of DST),
        # but 2016-03-12 02:00 + 1 day yields NULL.
        expected = cat(
            2,
            NullableArray(ZonedDateTime(2016, 3, 12, 3, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, 3, winnipeg)),
            NullableArray(ZonedDateTime(2016, 3, 13, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 14, 1, winnipeg)),
            cat(
                1,
                Nullable(ZonedDateTime(2016, 3, 13, 1, winnipeg)),
                Nullable{ZonedDateTime}(),
                NullableArray(ZonedDateTime(2016, 3, 13, 3, winnipeg):Hour(1):ZonedDateTime(2016, 3, 14, winnipeg))
            )
        )
        @test isequal(td2, expected)
        =#
    end

    @testset "fall back" begin
        #= Static Offsets
        td1 = NullableArray(ZonedDateTime(2016, 11, 5, winnipeg):Hour(1):ZonedDateTime(2016, 11, 6, winnipeg))
        td2 = static_offset(td1, Day(1))
        # We might expect to see every hour on 2016-11-06, but there are two occurrences of 01:00
        # due to DST and we'll only see the first one (because we're shifting forward in time, and
        # we get the nearest hour among the possible hours).
        expected = NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 11, 6, winnipeg),
                ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
                ZonedDateTime(2016, 11, 6, 2, winnipeg):Hour(1):ZonedDateTime(2016, 11, 7, winnipeg)
            )
        )
        @test isequal(td2, cat(2, expected))

        td3 = NullableArray(ZonedDateTime(2016, 11, 6, winnipeg):Hour(1):ZonedDateTime(2016, 11, 7, winnipeg))
        td4 = static_offset(td3, Day(-1))
        # Since DST means that 2016-11-06 01:00 occurs twice, when shifted back 1 day we expect
        # 2016-11-05 01:00 to occur twice.
        expected = NullableArray(
            cat(
                1,
                ZonedDateTime(2016, 11, 5, winnipeg),
                ZonedDateTime(2016, 11, 5, 1, winnipeg),
                ZonedDateTime(2016, 11, 5, 1, winnipeg),
                ZonedDateTime(2016, 11, 5, 2, winnipeg):Hour(1):ZonedDateTime(2016, 11, 6, winnipeg)
            )
        )
        @test isequal(td4, cat(2, expected))
        =#
    end
end

#=
TODO: dynamic offset tests
match_hourofday = DynamicOffset(; fallback=Dates.Day(-1))
match_hourofweek = DynamicOffset(; fallback=Dates.Week(-1))
match_hourofday_tuesday = DynamicOffset(; match=t -> Dates.dayofweek(t) == Dates.Tuesday)
=#

# TODO: test CustomOffset

# TODO: test CompositeOffset
# include tests that verify that multiple offsets applied at once are the same as
# applying those offsets one at a time in sequence

# TODO: test multiple columns of offsets (for observations function)

# TODO: test applying offsets to nullables (the only thing that is different is the isnull check)
