# ----- UTILITY FUNCTIONS -----

"""
  hourofweek(dt::TimeType) -> Int64

Returns the hour of the week as an Int64 in the range 0 through 167.

For locales in which weeks can have more or fewer than 168 hours (those that observe DST),
two consecutive hours may return the same result (or an integer may be skipped, as the
case may be).
"""
hourofweek(d::TimeType) = (dayofweek(d) - 1) * 24 + hour(d)
# TODO: Not actually used here, but useful. Should probably go in Curt's DateUtils.jl repo.

# Math between a single `Period` and a range of `DateTime`/`ZonedDateTime`s already works.
# Allows arithmetic between a `DateTime`/`ZonedDateTime`/`Period` and a range of `Period`s.
# TODO: Should go in julia/base/dates/ranges.jl:
.+{T<:Period}(x::Union{TimeType,Period}, r::Range{T}) = (x + first(r)):step(r):(x + last(r))
.+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = x .+ r
+{T<:Period}(x::Union{TimeType, Period}, r::Range{T}) = x .+ r
.-{T<:Period}(r::Range{T}, x::Union{TimeType,Period}) = (first(r) - x):step(r):(last(r) - x)
-{T<:Period}(r::Range{T}, x::Union{TimeType, Period}) = r .- x
