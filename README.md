[![Build Status](https://github.com/mirkobunse/MetaConfigurations.jl/workflows/CI/badge.svg)](https://github.com/mirkobunse/MetaConfigurations.jl/actions) [![codecov](https://codecov.io/gh/mirkobunse/MetaConfigurations.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mirkobunse/MetaConfigurations.jl)

# MetaConfigurations.jl

Define a set of configurations as a single, more abstract and comprehensive meta-configuration.

```julia
] add MetaConfigurations
```

Besides providing functions for manipulating configurations, MetaConfigurations.jl is also a meta package for a common API through which configuration file handlers like [JSON.jl](https://github.com/JuliaIO/JSON.jl) and [YAML.jl](https://github.com/JuliaData/YAML.jl) are unified.


## Motivation

Assume you want to describe four experiments, each of which consists of a combination of two parameters.

```
# experiment 1
description: "Experiment with α=0.1 and β=95%"
alpha: 0.1
beta: 95%
```

```
# experiment 2
description: "Experiment with α=0.01 and β=95%"
alpha: 0.01
beta: 95%
```

```
# experiment 3
description: "Experiment with α=0.1 and β=97.5%"
alpha: 0.1
beta: 97.5%
```

```
# experiment 4
description: "Experiment with α=0.01 and β=97.5%"
alpha: 0.01
beta: 97.5%
```

MetaConfigurations.jl can derive these combinations from a single, more abstract and comprehensive representation, which we call a meta-configuration:

```
description: "Experiment with α=$(alpha) and β=$(beta)"
alpha:
  - 0.1
  - 0.01
beta:
  - 95%
  - 97.5%
```

The desired list of experiments is obtained from this meta-configuration by expansions and String interpolations:

```julia
using MetaConfigurations
configurations = expand(
    parsefile("example.yml"), # read the above meta-configuration
    "alpha",
    "beta"
) # create a list of cells from the matrix spanned by alpha and beta
interpolate!.(configurations, "description") # fill in the placeholders in each description
```


## Deriving configurations from meta-configurations

Let's take a closer look on the operations provided by this package. We have already seen the first two of them.

**MetaConfigurations.expand:**
We can expand any property that has a vector of values, like the properties `alpha` and `beta` in the example above.
Consider at first the expansion of a single vector-valued property `p` with length `n`.
This expansion will result in a vector of `n` configurations, in each of which `p` has only one of its initial values.
The expansion of multiple properties, like above, is taken out sequentially.
By expanding properties, we transform a single, comprehensive meta-configuration into a set of configurations.

**MetaConfigurations.interpolate:**
Interpolation substitutes all placeholders in a `String` property with the corresponding values of other properties in the same configuration.
In the above example, we have seen how the placeholders `$(alpha)` and `$(beta)` have been replaced with the actual values of `alpha` and `beta`.

**MetaConfigurations.patch:**
A patch defines an additional key-value pair in a copy of a configuration.
For example, we might want wo create a copy of the above `configurations` vector in which each configuration has a fixed value for an additional property `gamma`:

```julia
patch.(configurations; gamma=1000)
```


## Reading and writing configuration files

MetaConfigurations.jl is also a meta-package that unifies the APIs
of [JSON.jl](https://github.com/JuliaIO/JSON.jl) and [YAML.jl](https://github.com/JuliaData/YAML.jl).
To which backend an operation is delegated is automatically determined from the file name extension.

```julia
using MetaConfigurations

cfg = parsefile("example.yml") # read from a YAML file
save("example.json", cfg) # store it as a JSON file
```

By default, MetaConfigurations.jl parses files into objects of the type `Dict{String,Any}`. You can change this behaviour through the `dicttype` argument, e.g. to preserve the order of the configuration file or to use `Symbol` instances as keys.

```julia
using MetaConfigurations, OrderedCollections

cfg = parsefile("example.yml", dicttype=OrderedDict{Symbol, Any})
```


## Finding properties

You can recursively find properties by their key:

```julia
# continuing the introductory example, ..
find(configurations, "description")
```

```
4-element Array{String,1}:
 "Experiment with α=0.1 and β=95%"
 "Experiment with α=0.1 and β=97.5%"
 "Experiment with α=0.01 and β=95%"
 "Experiment with α=0.01 and β=97.5%"
```
