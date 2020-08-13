# parsefile just needs to call the parser
parsefile(::FileType{:yml}, filename::AbstractString) =
    YAML.load_file(filename)

# ".yaml" is just an alias for ".yml"
parsefile(::FileType{:yaml}, filename::AbstractString) =
    parsefile(FileType(:yml), filename)
