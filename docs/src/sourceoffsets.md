# SourceOffsets

A `SourceOffset` is an abstract type that allows the user to define the relationship
between a forecast target date (or `sim_now`) and the date associated with the input data
used to generate that forecast (also called the "observation date").

```@docs
StaticOffset
LatestOffset
DynamicOffset
CustomOffset
CompoundOffset
apply
```

