YamlFileType = Union{FileType{:yml}, FileType{:yaml}} # allow both extensions

# parsefile just needs to call the parser
parsefile(::YamlFileType, filename::AbstractString) =
    YAML.load_file(filename)

# save just needs to call the writer
save(::YamlFileType, filename::AbstractString, configuration::AbstractDict) =
    YAML.write_file(filename, configuration)
