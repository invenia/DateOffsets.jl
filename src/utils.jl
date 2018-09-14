function repr_period(io::IO, period::Period)
    print(io, nameof(typeof(period)), '(', Dates.value(period), ')')
end

always(args...) = true

Base.print(io::IO, f::typeof(always)) = print(io, "always")
