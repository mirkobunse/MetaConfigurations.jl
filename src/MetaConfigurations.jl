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

export expand, find, interpolate, interpolate!, parsefile, patch, save

include("io.jl")

"""
    find(configuration, key)

Recursively find all values which are indexed by the `key` in the `configuration` tree.
"""
find(c::AbstractDict{K,V}, k::K) where {K, V} =
    (r = Any[]; _find!(r, c, k); [x for x in r]) # assume Any[], then narrow the type
find(c::AbstractVector, k::Any) =
    (r = Any[]; _find!(r, c, k); [x for x in r])

_find!(r::Vector{Any}, c::AbstractDict{K,V}, key::K) where {K, V} =
    for (k, v) in c
        if k == key
            push!(r, v)
        end
        _find!(r, v, key)
    end

_find!(r::Vector{Any}, c::AbstractVector, key::Any) =
    for v in c
        _find!(r, v, key)
    end

_find!(r::Vector{Any}, c::Any, key::Any) = nothing

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
function patch(conf::AbstractDict, args::Pair...; kwargs...)
    key_type = eltype(keys(conf)) # ensure the key type is preserved
    val_type = promote_type(eltype(values(conf)), eltype(last.(args)))
    return typeof(conf).name.wrapper{key_type,val_type}(
        conf..., args..., [eltype(keys(conf))(k) => v for (k, v) in kwargs]...
    ) # the value type might become more general
end

_INTERPOLATE_DOC = """
    interpolate(configuration, property; kwargs...)
    interpolate!(configuration, property; kwargs...)

Interpolation substitutes all placeholders in the `property` with the corresponding values
of other properties in the same `configuration`.

# Details

A placeholder of another property `p` must start with a dollar sign and wrap the
name of that property in parantheses: `\$(p)`.

Nested configurations are interpolated by specifying their path as a vector `property`.
For instance, `["foo", "bar"]` will interpolate the property `bar`,
which is nested in the property `foo`.

Keyword arguments allow to substitute placeholders with arbitrary values,
in addition to the substition with values of existing properties.

# Examples

    cfg = Dict("a" => 1, "b" => "Here, a is \$(a)")
    interpolate!(cfg, "b")
    cfg

    # Dict{String,Any} with 2 entries:
    #  "a" => 1
    #  "b" => "Here, a is 1"
"""
@doc _INTERPOLATE_DOC interpolate
@doc _INTERPOLATE_DOC interpolate!

function interpolate(conf::AbstractDict{K,V}, property::AbstractVector{K}; kwargs...) where {K, V}
    replace(_getindex(conf, property...), r"\$\([a-zA-Z_]+\)" => s -> begin
        s = s[3:end-1] # remove leading '$' and enclosing brackets
        if haskey(conf, K(s))
            conf[K(s)]
        elseif haskey(kwargs, Symbol(s))
            kwargs[Symbol(s)]
        else
            error("Key $(K(s)) not in config and not supplied as a keyword argument.")
        end
    end)
end

interpolate(conf::AbstractDict{K,V}, property::K; kwargs...) where {K, V} =
    interpolate(conf, [property]; kwargs...)

interpolate!(conf::AbstractDict{K,V}, property::AbstractVector{K}; kwargs...) where {K, V} =
    _setindex!(conf, interpolate(conf, property; kwargs...), property...)

interpolate!(conf::AbstractDict{K,V}, property::K; kwargs...) where {K, V} =
    interpolate!(conf, [property]; kwargs...)


"""
    expand(configuration, property...)

Expansion a vector-valued property `p` with length `n` will result in a vector of `n`
configurations, in each of which `p` has only one of its initial values.

# Details

Nested configurations are expanded by specifying their path as a vector `property`.
For instance, `["foo", "bar"]` will expand the property `bar`,
which is nested in the property `foo`.

The expansion of multiple properties is taken out sequentially.

# Examples

    cfg = Dict("a" => [1, 2], "b" => -1)
    expand(cfg, "a")

    # 2-element Array{Dict{Any,Any},1}:
    #  Dict("a" => 1, "b" => -1)
    #  Dict("a" => 2, "b" => -1)
"""
expand(config::AbstractDict, property::Any) =
    [ typeof(config)(deepcopy(config)..., property => v) for v in _getindex(config, property) ]

# deeper in the configuration tree, it gets slightly more complex
expand(config::AbstractDict, property::AbstractVector) =
    [ begin
        c = deepcopy(config)
        _setindex!(c, v, property...)
        c
    end for v in vcat(_getindex(config, property...)...) ]

# multiple expansions
expand(config::AbstractDict, properties::Any...) = # Any also matches AbstractVectors
    vcat([ expand(expansion, properties[2:end]...) for expansion in expand(config, properties[1]) ]...)

# functions that complement the usual indexing with varargs
# (overriding Base.getindex and Base.setindex would screw up these methods)
@inbounds _getindex(val::AbstractDict, keys::Any...) =
    if length(keys) > 1
        _getindex(val[keys[1]], keys[2:end]...) # descend into the val[keys[1]] sub-tree
    elseif haskey(val, keys[1])
        val[keys[1]]
    else
        Any[nothing] # return a dummy value - this will never be set (see _setindex! below)
    end

@inbounds _getindex(arr::AbstractVector, keys::Any...) =
    [ try _getindex(val, keys...) catch; end for val in arr ]

@inbounds _setindex!(val::AbstractDict, value::Any, keys::Any...) = 
    if length(keys) > 1
        _setindex!(val[keys[1]], value, keys[2:end]...)
    elseif haskey(val, keys[1]) # only update existing mappings because expansion never adds new mappings
        val[keys[1]] = value
    end

@inbounds _setindex!(arr::AbstractVector, value::Any, keys::Any...) =
    [ try _setindex!(val, value, keys...) catch; end for val in arr ]

end # module
