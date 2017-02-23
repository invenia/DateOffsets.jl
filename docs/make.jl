using Documenter, DateOffsets

makedocs(
    modules=[DateOffsets],
    format=:html,
    pages=[
        "Home"=>"DateOffsets.md",
        "Horizons"=>"horizons.md",
        "Source Offsets"=>"sourceoffsets.md",
        "Observation Dates"=>"observations.md",
        "Index"=>"index.md"
    ],
    repo="https://gitlab.invenia.ca/invenia/DateOffsets.jl/blob/{commit}{path}#L{line}",
    sitename="DateOffsets.jl",
    authors="Invenia Technical Computing",
    assets=["assets/invenia.css"],
)
