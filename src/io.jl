using JSON, YAML

# a value type used to dispatch on file name extensions
struct FileType{x} end
FileType(x::Symbol) = FileType{x}()

YAMLFileType = Union{FileType{:yml}, FileType{:yaml}} # allow both extensions
JSONFileType = FileType{:json}

function filetype(path::AbstractString)
    extension_split = split(basename(path), ".")
    if length(extension_split) < 2
        throw(ArgumentError("The path \"$path\" has no extension"))
    end
    extension = lowercase(extension_split[end])
    return FileType(Symbol(extension))
end

"""
    parsefile(filename)

Parse a configuration file into a nested `Dict`.

Parsing a file requires a corresponding parser package,
like `YAML.jl` or `JSON.jl`, to be loaded.
To which parser `parsefile` delegates depends on the `filename` extension.

# Examples

    using MetaConfigurations
    cfg = parsefile("foobar.yml") # breaks

    using YAML
    cfg = parsefile("foobar.yml") # now it works
"""
parsefile(filename::AbstractString) =
    parsefile(filetype(filename), filename)

parsefile(::FileType{x}, filename::AbstractString) where x =
    throw(ArgumentError("No parser loaded for the file name extension .$x"))

"""
    save(filename, configuration)

Write the `configuration` to a file.

Writing a file requires a corresponding writer package,
like `YAML.jl` or `JSON.jl`, to be loaded.
To which writer `save` delegates depends on the `filename` extension.

# Examples

    using MetaConfigurations
    save("foobar.yml", Dict("a" => 1, "b" => 2)) # breaks

    using YAML
    save("foobar.yml", Dict("a" => 1, "b" => 2)) # now it works
"""
save(filename::AbstractString, configuration::AbstractDict) =
    save(filetype(filename), filename, configuration)

save(::FileType{x}, filename::AbstractString, configuration::AbstractDict) where x =
    throw(ArgumentError("No writer loaded for the file name extension .$x"))

# parsefile just needs to call the respective parser
parsefile(::YAMLFileType, filename::AbstractString) =
    YAML.load_file(filename)
parsefile(::JSONFileType, filename::AbstractString) =
    JSON.parsefile(filename)

# save just needs to call the respective writer
save(::YAMLFileType, filename::AbstractString, configuration::AbstractDict) =
    YAML.write_file(filename, configuration)
save(::JSONFileType, filename::AbstractString, configuration::AbstractDict) =
    open(filename, "w") do io
        JSON.print(io, configuration, 2) # pretty-format with indent=2
    end
