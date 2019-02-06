using Documenter, DateOffsets

makedocs(
    modules=[DateOffsets],
    format=Documenter.HTML(),
    pages=[
        "Home"=>"index.md",
        "Horizons"=>"horizons.md",
        "Source Offsets"=>"sourceoffsets.md",
        "Observation Dates"=>"observations.md",
        "Index"=>"apiindex.md"
    ],
    repo="https://gitlab.invenia.ca/invenia/DateOffsets.jl/blob/{commit}{path}#L{line}",
    sitename="DateOffsets.jl",
    authors="Curtis Vogt, Gem Newman",
    assets=["assets/invenia.css"],
    strict = true,
    checkdocs = :none,
)
