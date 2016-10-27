using Horizons
using TimeZones
using Intervals
using NullableArrays
using Base.Test
using Base.Dates


utc = TimeZone("UTC")
winnipeg = TimeZone("America/Winnipeg")


# ----- hourofweek -----
dt = DateTime(2016, 8, 1)   # Monday
for h in 0:167
    @test hourofweek(dt + Hour(h)) == h
    @test hourofweek(ZonedDateTime(dt + Hour(h), utc)) == h
    @test hourofweek(ZonedDateTime(dt + Hour(h), winnipeg)) == h
end
@test hourofweek(DateTime(2016, 8, 2)) == hourofweek(DateTime(2016, 8, 2, 0, 59, 59, 999))

# TODO: hourofweek should probably go in Curt's DateUtils repo

# TODO: Interface with Aron about how DST is handled for data fetching. (He will have
# opinions!)


# ----- horizon_hourly -----
hours = Hour(1):Hour(3)
minutes = Minute(15):Minute(15):Minute(120)

# Basic
sim_now = ZonedDateTime(2016, 1, 1, 9, 35, winnipeg)
results = horizon_hourly(sim_now, hours)
@test collect(results) == [
    ZonedDateTime(2016, 1, 1, 11, winnipeg),
    ZonedDateTime(2016, 1, 1, 12, winnipeg),
    ZonedDateTime(2016, 1, 1, 13, winnipeg)
]
results = horizon_hourly(sim_now, minutes; ceil_to=Minute(15))
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

# "Spring Forward"
sim_now = ZonedDateTime(2016, 3, 12, 23, 59, winnipeg)
results = horizon_hourly(sim_now, hours)
@test collect(results) == [
    ZonedDateTime(2016, 3, 13, 1, winnipeg),
    ZonedDateTime(2016, 3, 13, 3, winnipeg),
    ZonedDateTime(2016, 3, 13, 4, winnipeg)
]
sim_now = ZonedDateTime(2016, 3, 13, 0, 59, winnipeg)
results = horizon_hourly(sim_now, minutes; ceil_to=Minute(15))
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

# "Fall Back"
sim_now = ZonedDateTime(2016, 11, 5, 23, 59, winnipeg)
results = horizon_hourly(sim_now, hours)
@test collect(results) == [
    ZonedDateTime(2016, 11, 6, 1, winnipeg, 1),
    ZonedDateTime(2016, 11, 6, 1, winnipeg, 2),
    ZonedDateTime(2016, 11, 6, 2, winnipeg)
]
sim_now = ZonedDateTime(2016, 11, 6, 0, 59, winnipeg)
results = horizon_hourly(sim_now, minutes; ceil_to=Minute(15))
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


# ----- horizon_daily -----

# Basic
sim_now = ZonedDateTime(2016, 1, 1, 9, 35, winnipeg)
results = horizon_daily(sim_now)
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
results = horizon_daily(
    sim_now; resolution=Hour(2), days_ahead=Day(3), days_covered=Day(2), floor_to=Week(1)
)
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

# "Spring Forward"
sim_now = ZonedDateTime(2016, 3, 12, 9, 35, winnipeg)
results = horizon_daily(sim_now)
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

# "Fall Back"
sim_now = ZonedDateTime(2016, 11, 5, 9, 35, winnipeg)
results = horizon_daily(sim_now)
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


# ----- observation_dates -----

# Basic
sim_now = ZonedDateTime(2016, 8, 3, 0, 10, winnipeg)
target_dates = horizon_hourly(sim_now, Hour(2):Hour(4))
o, s = observation_dates(target_dates, sim_now, Day(1), Day(2))
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

# "Spring Forward"
# Assumes that the current relationship between sim_now and target_dates remains the same.
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

# "Fall Back"
# Assumes that the current relationship between sim_now and target_dates remains the same.
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

# TODO: Add test cases where the sim_nows will hit an invalid/missing and/or ambiguous zdt

# ----- static_offset -----
# cat(2, X) is used below in several cases to convert a vector into a 2D array with 1 column
td0 = NullableArray(ZonedDateTime(2016, 10, 1, 1, winnipeg):Hour(1):ZonedDateTime(2016, 10, 2, winnipeg))
td1 = static_offset(td0, Day(0))    # Should be the same.
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

# "Spring Forward"
td5 = NullableArray(ZonedDateTime(2016, 3, 12, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 13, winnipeg))
td6 = static_offset(td5, Hour(2), Hour(24), Day(1))
# Note that 2016-03-12 02:00 + 24 hours yields 2016-03-13 03:00 (because of DST), but
# 2016-03-12 02:00 + 1 day yields NULL.
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
@test isequal(td6, expected)

# "Fall Back"
td7 = NullableArray(ZonedDateTime(2016, 11, 5, winnipeg):Hour(1):ZonedDateTime(2016, 11, 6, winnipeg))
td8 = static_offset(td7, Day(1))
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
@test isequal(td8, cat(2, expected))

td9 = NullableArray(ZonedDateTime(2016, 11, 6, winnipeg):Hour(1):ZonedDateTime(2016, 11, 7, winnipeg))
td10 = static_offset(td9, Day(-1))
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
@test isequal(td10, cat(2, expected))


# Test latest_target
# WILL HAVE TO USE MEND to edit/replace call to table_metadata in latest_target


# Test recent_offset (incl. multi-column inputs)


# Test dynamic_offset (incl. multi-column inputs)


# Test dynamic_hourofday (incl. multi-column inputs)


# Test dynamic_hourofweek (incl. multi-column inputs)


