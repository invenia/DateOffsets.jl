using Documenter, DateOffsets

makedocs(;
    modules=[DateOffsets],
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true",
        assets=["assets/invenia.css"],
    ),
    pages=[
        "Home"=>"index.md",
        "Horizons"=>"horizons.md",
        "Offsets"=>"offsets.md",
        "Observation Dates"=>"observations.md",
        "Index"=>"apiindex.md"
    ],
    repo="https://gitlab.invenia.ca/invenia/DateOffsets.jl/blob/{commit}{path}#L{line}",
    sitename="DateOffsets.jl",
    authors="Invenia Technical Computing Corporation",
    strict = true,
    checkdocs = :none,
)
