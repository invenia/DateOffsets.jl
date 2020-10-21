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
        "Observations"=>"observations.md",
        "Production Use Cases"=>"use_cases.md",
        "API"=>"api.md"
    ],
    repo="https://gitlab.invenia.ca/invenia/DateOffsets.jl/blob/{commit}{path}#L{line}",
    sitename="DateOffsets.jl",
    authors="Invenia Technical Computing Corporation",
    strict = true,
    checkdocs = :none,
)
