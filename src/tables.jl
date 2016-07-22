# ----- TABLE METADATA -----

type Table
    name::Symbol
    latest::Dict{ZonedDateTime, ZonedDateTime}

    Table(name::Symbol) = new(name, Dict{ZonedDateTime, ZonedDateTime}())
end

Table(name::AbstractString) = Table(Symbol(name))

"""
Given a sim_now and a table name, estimates the latest available target_date.
"""
function latest_target(table::Table, sim_now::ZonedDateTime)
    if !haskey(table.latest, sim_now)
        meta = table_metadata(table.name)
        sim_now = astimezone(sim_now, meta[:feed_tz])

        latest_release = estimate_latest_release(
            sim_now, meta[:publish_interval], meta[:publish_offset], meta[:feed_runtime]
        )

        table.latest[sim_now] = estimate_content_end(
            latest_release, meta[:content_interval], meta[:content_offset]
        )
    end

    return table.latest[sim_now]
end

function latest_target(table::Table, sim_now::AbstractArray{ZonedDateTime})
    return map(s -> latest_target(table, s), sim_now)
end


# ----- FAKE DB INTERFACE MOCK-UP -----

# This should go in the test cases to mock up the tables we're testing against.
function table_metadata(tablename)
    #=
    # PJM Day-Ahead Shadow Prices
    publish_interval = Second(Day(1))
    publish_offset = Second(Hour(13))
    content_interval = Second(Day(1))
    content_offset = Second(Day(2))
    datafeed_runtime = Second(Minute(20))  # Ballparked
    # PJM Load Forecasts
    publish_interval = Second(Minute(30))
    publish_offset = Second(Minute(20))
    content_interval = Second(Day(1))
    content_offset = Second(Day(7))
    datafeed_runtime = Second(Minute(20))  # Ballparked
    # PJM Real-Time HTTP
    publish_interval = Second(Day(1))
    publish_offset = Second(Hour(11))
    content_interval = Second(Day(1))
    content_offset = Second(Day(0))
    datafeed_runtime = Second(Minute(20))  # Ballparked
    # PJM Real-Time EDataFeed
    publish_interval = Second(Hour(1))
    publish_offset = Second(Minute(30))
    content_interval = Second(Hour(1))
    content_offset = Second(Hour(0))
    datafeed_runtime = Second(Minute(20))  # Ballparked
    =#
    if tablename == :pjm_shadow
        return Dict(
            :publish_interval => Day(1),
            :publish_offset => Hour(13),
            :content_interval => Day(1),
            :content_offset => Day(2),
            :feed_runtime => Minute(20),
            :feed_tz => TimeZone("America/New_York")
        )
    elseif tablename == :pjm_load
        return Dict(
            :publish_interval => Minute(30),
            :publish_offset => Minute(20),
            :content_interval => Day(1),
            :content_offset => Day(7),
            :feed_runtime => Minute(20),
            :feed_tz => TimeZone("America/New_York")
        )
    elseif tablename == :pjm_http
        return Dict(
            :publish_interval => Day(1),
            :publish_offset => Hour(11),
            :content_interval => Day(1),
            :content_offset => Second(0),
            :feed_runtime => Minute(20),
            :feed_tz => TimeZone("America/New_York")
        )
    elseif tablename == :pjm_edf
        return Dict(
            :publish_interval => Hour(1),
            :publish_offset => Minute(30),
            :content_interval => Hour(1),
            :content_offset => Second(0),
            :feed_runtime => Minute(20),
            :feed_tz => TimeZone("America/New_York")
        )
    end
end

"""
Estimates the latest release date given the current time and the typical publication
interval and offset. Useful in estimating the avaialble content end at a specific time.
"""
function estimate_latest_release(sim_now, publish_interval, publish_offset, feed_runtime)
    return floor(sim_now - publish_offset - feed_runtime, publish_interval) + publish_offset
end

"""
Estimates the content end given the release date and the content interval and offset.
"""
function estimate_content_end(release_date, content_interval, content_offset)
    return floor(release_date, content_interval) + content_offset
end

