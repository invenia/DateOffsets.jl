# ----- UTILITY FUNCTIONS -----

"""
Returns an integer indicating the hour of week (0 through 167). For locales in which weeks
can have more or fewer than 168 hours (those that observe DST), two consecutive hours may
return the same result (or an integer may be skipped, as the case may be). This was judged
preferable to having a potential 169th hour for our use case.
"""
hourofweek(d::TimeType) = (dayofweek(d) - 1) * 24 + hour(d)
# TODO: Not actually used, but seems like it could be useful. Keep?
# Should probably go in Curt's DateUtils.jl repo.

# Math between a single `Period` and a range of `DateTime`/`ZonedDateTime`s already works.
# Allows arithmetic between a `DateTime`/`ZonedDateTime`/`Period` and a range of `Period`s.
# Should go in julia/base/dates/ranges.jl:
.+{T<:Period}(x::Union{TimeType,Period}, r::Range{T}) = (x + first(r)):step(r):(x + last(r))
.+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(x::Union{TimeType, Period}, r::Range{T}) = x .+ r
.-{T<:Period}(r::Range{T}, x::Union{TimeType,Period}) = (first(r) - x):step(r):(last(r) - x)
-{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = r .- x
