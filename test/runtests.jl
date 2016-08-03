using Horizons
using TimeZones
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


# ----- horizon_hourly -----
hours = Hour(1):Hour(3)
minutes = Minute(15):Minute(15):Minute(120)

# Basic
sim_now = ZonedDateTime(2016, 1, 1, 9, 35, winnipeg)
results = horizon_daily(sim_now, hours)
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
results = horizon_hourly(sim_now, hours)
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
result = observation_dates(target_dates, sim_now, Day(1), Day(2))
@test result == (
    [
        ZonedDateTime(2016, 8, 1, 3, winnipeg),
        ZonedDateTime(2016, 8, 1, 4, winnipeg),
        ZonedDateTime(2016, 8, 1, 5, winnipeg),
        ZonedDateTime(2016, 8, 2, 3, winnipeg),
        ZonedDateTime(2016, 8, 2, 4, winnipeg),
        ZonedDateTime(2016, 8, 2, 5, winnipeg),
        ZonedDateTime(2016, 8, 3, 3, winnipeg),
        ZonedDateTime(2016, 8, 3, 4, winnipeg),
        ZonedDateTime(2016, 8, 3, 5, winnipeg)
    ], [
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
)
result = observation_dates(target_dates, sim_now, Day(1), Day(1) .. Day(2), Day(4) .. Day(5))
@test result == (
    [
        ZonedDateTime(2016, 7, 28, 3, winnipeg),
        ZonedDateTime(2016, 7, 28, 4, winnipeg),
        ZonedDateTime(2016, 7, 28, 5, winnipeg),
        ZonedDateTime(2016, 7, 29, 3, winnipeg),
        ZonedDateTime(2016, 7, 29, 4, winnipeg),
        ZonedDateTime(2016, 7, 29, 5, winnipeg),
        ZonedDateTime(2016, 8, 1, 3, winnipeg),
        ZonedDateTime(2016, 8, 1, 4, winnipeg),
        ZonedDateTime(2016, 8, 1, 5, winnipeg),
        ZonedDateTime(2016, 8, 2, 3, winnipeg),
        ZonedDateTime(2016, 8, 2, 4, winnipeg),
        ZonedDateTime(2016, 8, 2, 5, winnipeg)
    ], [
        ZonedDateTime(2016, 7, 28, 0, 10, winnipeg),
        ZonedDateTime(2016, 7, 28, 0, 10, winnipeg),
        ZonedDateTime(2016, 7, 28, 0, 10, winnipeg),
        ZonedDateTime(2016, 7, 29, 0, 10, winnipeg),
        ZonedDateTime(2016, 7, 29, 0, 10, winnipeg),
        ZonedDateTime(2016, 7, 29, 0, 10, winnipeg),
        ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
        ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
        ZonedDateTime(2016, 8, 1, 0, 10, winnipeg),
        ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
        ZonedDateTime(2016, 8, 2, 0, 10, winnipeg),
        ZonedDateTime(2016, 8, 2, 0, 10, winnipeg)
    ]
)

# "Spring Forward"
# Assumes that the current relationship between sim_now and target_dates remains the same.
sim_now = ZonedDateTime(2016, 3, 13, 0, 10, winnipeg)
target_dates = horizon_daily(sim_now)
result = observation_dates(target_dates, sim_now, Day(1), Day(2))
@test result == (
    cat(
        1,
        ZonedDateTime(2016, 3, 12, winnipeg):Hour(1):ZonedDateTime(2016, 3, 12, 23, winnipeg),
        ZonedDateTime(2016, 3, 13, winnipeg):Hour(1):ZonedDateTime(2016, 3, 14, winnipeg),
        ZonedDateTime(2016, 3, 14, 1, winnipeg):Hour(1):ZonedDateTime(2016, 3, 15, winnipeg),
    ),
    cat(
        1,
        repmat([sim_now - Day(2)], 24),
        repmat([sim_now - Day(1)], 24),
        repmat([sim_now], 24)
    )
)

# "Fall Back"
# Assumes that the current relationship between sim_now and target_dates remains the same.
sim_now = ZonedDateTime(2016, 11, 6, 0, 10, winnipeg)
target_dates = horizon_hourly(sim_now, Hour(2):Hour(4))


# Test observation_dates


# Test static_offset (incl. multiple offsets, then additionoal multiple offsets)


# Test recent_offset (incl. multi-column inputs)


# Test dynamic_offset (incl. multi-column inputs)


# Test dynamic_hourofday (incl. multi-column inputs)


# Test dynamic_hourofweek (incl. multi-column inputs)


# Test latest_target


