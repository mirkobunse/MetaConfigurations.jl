parsefile(::FileType{:json}, filename::AbstractString) =
    JSON.parsefile(filename)

save(::FileType{:json}, filename::AbstractString, configuration::AbstractDict) =
    open(filename, "w") do io
        JSON.print(io, configuration, 2) # pretty-format with indent=2
    end
