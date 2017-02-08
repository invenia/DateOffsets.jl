# Date Offsets

```@contents
Pages = ["index.md", "horizons.md", "sourceoffsets.md", "observations.md"]
```

[DateOffsets.jl](https://gitlab.invenia.ca/invenia/DateOffsets.jl) provides the types and
functions necessary to generate dates with specific temporal offsets for use in training
and forecasting.

[Horizons](@ref) allow the user to define the relationship between the time at which a
forecast runs (`sim_now`) and the target dates of that forecast.

[SourceOffsets](@ref) allow the user to define the relationship between a forecast
target date (or `sim_now`) and the date associated with the input data used to generate
that forecast (also called the "observation date").

```@index
```
