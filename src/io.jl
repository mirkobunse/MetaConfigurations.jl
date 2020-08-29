using JSON, YAML

# a value type used to dispatch on file name extensions
struct FileType{x} end
FileType(x::Symbol) = FileType{x}()

YAMLFileType = Union{FileType{:yml}, FileType{:yaml}} # allow both extensions
JSONFileType = FileType{:json}

function filetype(filename::AbstractString)
    extension_split = split(basename(filename), ".")
    if length(extension_split) < 2
        throw(ArgumentError("The filename \"$filename\" has no extension"))
    end
    extension = lowercase(extension_split[end])
    return FileType(Symbol(extension))
end

"""
    parsefile(filename; dicttype=Dict{String,Any})

Parse a configuration file into a nested dictionary.

The actual parsing is delegated to a parser package like YAML.jl or JSON.jl,
depending on the `filename` extension. You can alter the return type of the
function by specifying a custom `dicttype`.
"""
parsefile(filename::AbstractString; dicttype::Type{T}=Dict{String,Any}) where T<:AbstractDict =
    parsefile(filetype(filename), dicttype, filename)

parsefile(::FileType{x}, dicttype::Type{T}, filename::AbstractString) where {x, T<:AbstractDict} =
    throw(ArgumentError("I don't know how to parse the file name extension .$x"))

"""
    save(filename, configuration)

Write the `configuration` to a file.

The actual writing is delegated to a writer package like YAML.jl or JSON.jl,
depending on the `filename` extension.
"""
save(filename::AbstractString, configuration::AbstractDict) =
    save(filetype(filename), filename, configuration)

save(::FileType{x}, filename::AbstractString, configuration::AbstractDict) where x =
    throw(ArgumentError("No writer loaded for the file name extension .$x"))

# parsefile just needs to call the respective parser
parsefile(::YAMLFileType, dicttype::Type{T}, filename::AbstractString) where T<:AbstractDict =
    YAML.load_file(filename; dicttype=dicttype)
parsefile(::JSONFileType, dicttype::Type{T}, filename::AbstractString) where T<:AbstractDict =
    JSON.parsefile(filename; dicttype=dicttype)

# save just needs to call the respective writer
save(::YAMLFileType, filename::AbstractString, configuration::AbstractDict) =
    YAML.write_file(filename, configuration)
save(::JSONFileType, filename::AbstractString, configuration::AbstractDict) =
    open(filename, "w") do io
        JSON.print(io, configuration, 2) # pretty-format with indent=2
    end
