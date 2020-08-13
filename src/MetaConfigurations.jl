# 
# MetaConfigurations.jl
# Copyright 2020 Mirko Bunse
# 
# 
# Meta-configurations comprehensively define sets of configurations.
# 
# 
# MetaConfigurations.jl is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with MetaConfigurations.jl.  If not, see <http://www.gnu.org/licenses/>.
# 
module MetaConfigurations

using Requires
export parsefile, patch, expand, interpolate, interpolate!


# load dynamic dependencies
function __init__()
    @require YAML="ddb6d928-2868-570f-bddf-ab3f9cf99eb6" include("yaml.jl")
end


# a value type that used to dispatch on file name extensions
struct FileType{x} end
FileType(x::Symbol) = FileType{x}()


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
function parsefile(filename::AbstractString)
    extension_split = split(basename(filename), ".")
    if length(extension_split) < 2
        throw(ArgumentError("filename=\"$filename\" has no extension"))
    end
    extension = lowercase(extension_split[end])
    return parsefile(FileType(Symbol(extension)), filename)
end

parsefile(::FileType{x}, filename::AbstractString) where x =
    throw(ArgumentError("No parser loaded for the file name extension .$x"))


"""
    patch(configuration, pair_patches...; kwarg_patches...)

Each of the patch arguments defines an additional key-value pair
in a copy of the `configuration`.

The pair patch syntax allows keys of arbitrary types,
while the keyword argument syntax can only handle proper `Symbol` instances.
No matter which syntax is used, all additional keys are being converted to `String`s.

# Examples

    cfg = Dict("a" => 1, "b" => 2)
    patch(cfg, c = 3)               # keyword argument syntax
    patch(cfg, "-2" => -2)          # pair syntax (more versatile)
    patch(cfg, "c"=>"foo"; d="bar") # combination of both
"""
patch(conf::AbstractDict{K, V}, args::Pair{K, V}...; kwargs...) where {K <: Any, V <: Any} =
    Dict(conf..., args..., [string(k) => v for (k, v) in kwargs]...)


_INTERPOLATE_DOC = """
    interpolate(configuration, property; kwargs...)
    interpolate!(configuration, property; kwargs...)

Interpolate the value of a `property` in some `configuration` with the values referenced therein.

For example, if the `configuration` specifies two properties `prop: "\$(foo)bar"` and
`foo: "bar"`, interpolating the value of `foo` into `prop` yields `prop: "barbar"`. Namely,
`\$(foo)` has been replaced by the value of `foo`. If only `prop: "\$(foo)bar"` is given but
no property `foo` is configured, you can specify it as a keyword argument, calling
`interpolate(conf, "prop", foo="bar")`, which yields the same result. In any case, `prop`
has to refer to `foo` with a dollar sign and enclosing brackets (`\$(foo)`).

The `property` may be a vector specifying a root-to-leaf path in the configuration tree.
"""
@doc _INTERPOLATE_DOC interpolate
@doc _INTERPOLATE_DOC interpolate!

function interpolate(conf::Dict{Any,Any}, property::AbstractArray; kwargs...)
    replace(_getindex(conf, property...), r"\$\([a-zA-Z_]+\)" => s -> begin
        s = s[3:end-1] # remove leading '$' and enclosing brackets
        if haskey(conf, s)
            conf[s]
        elseif haskey(kwargs, Symbol(s))
            kwargs[Symbol(s)]
        else
            error("Key $s not in config and not supplied as keyword argument.")
        end
    end)
end

interpolate(conf::Dict{Any,Any}, property::Any; kwargs...) =
    interpolate(conf, [property]; kwargs...)

interpolate!(conf::Dict{Any,Any}, property::AbstractArray; kwargs...) =
    _setindex!(conf, interpolate(conf, property; kwargs...), property...)

interpolate!(conf::Dict{Any,Any}, property::Any; kwargs...) =
    interpolate!(conf, [property]; kwargs...)


"""
    expand(configuration, property)

Expand the values of a `configuration` with the content of a `property` specified therein.

Expansion means that if the `property` is a vector with multiple elements, each element
defines a copy of the configuration where only this element is stored in the `property`.
Thus, a vector of configurations is returned, with all elements similar to the original
`configuration` but each containing another value of the `property`. The `property` may be
a vector specifying a root-to-leaf path in the configuration tree.
"""
expand(config::Dict{Any,Any}, property::Any) =
    [ Dict{Any,Any}(config..., property => v) for v in _getindex(config, property) ]

# deeper in the configuration tree, it gets slightly more complex
expand(config::Dict{Any,Any}, property::AbstractArray) =
    [ begin
        c = deepcopy(config)
        _setindex!(c, v, property...)
        c
    end for v in vcat(_getindex(config, property...)...) ]

# multiple expansions
expand(config::Dict{Any,Any}, properties::Any...) = # Any also matches AbstractArrays
    vcat([ expand(expansion, properties[2:end]...) for expansion in expand(config, properties[1]) ]...)

# functions that complement the usual indexing with varargs
# (overriding Base.getindex and Base.setindex would screw up these methods)
@inbounds _getindex(val::Dict, keys::Any...) =
    if length(keys) > 1
        _getindex(val[keys[1]], keys[2:end]...) # descend into the val[keys[1]] sub-tree
    elseif haskey(val, keys[1])
        val[keys[1]]
    else
        Any[nothing] # return a dummy value - this will never be set (see _setindex! below)
    end

@inbounds _getindex(arr::AbstractArray, keys::Any...) =
    [ try _getindex(val, keys...) catch; end for val in arr ]

@inbounds _setindex!(val::Dict, value::Any, keys::Any...) = 
    if length(keys) > 1
        _setindex!(val[keys[1]], value, keys[2:end]...)
    elseif haskey(val, keys[1]) # only update existing mappings because expansion never adds new mappings
        val[keys[1]] = value
    end

@inbounds _setindex!(arr::AbstractArray, value::Any, keys::Any...) =
    [ try _setindex!(val, value, keys...) catch; end for val in arr ]

end # module
