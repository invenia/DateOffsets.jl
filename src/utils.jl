function lax2nullable(dates::AbstractArray{LaxZonedDateTime}, ambiguous::Symbol=:last)
    # TODO: Square brackets only necessary in 0.5 to support dot syntax.
    return NullableArray(lax2nullable.(dates, [ambiguous]))
end

function lax2nullable(d::LaxZonedDateTime, ambiguous::Symbol=:last)
    return Nullable{ZonedDateTime}(isnonexistent(d) ? nothing : ZonedDateTime(d, ambiguous))
end
