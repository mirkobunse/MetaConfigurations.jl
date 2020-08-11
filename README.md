[![Build Status](https://travis-ci.org/mirkobunse/MetaConfigurations.jl.svg?branch=master)](https://travis-ci.org/mirkobunse/MetaConfigurations.jl) [![codecov](https://codecov.io/gh/mirkobunse/MetaConfigurations.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/mirkobunse/MetaConfigurations.jl)

# MetaConfigurations.jl

Define a set of configurations as a single, more abstract and comprehensive meta-configuration.

## Motivation

Assume you want to describe four experiments, each of which consists of a combination of two parameters.

```
experiments:
  - description: "Experiment with α=0.1 and β=95%"
    alpha: 0.1
    beta: 95%
  - description: "Experiment with α=0.01 and β=95%"
    alpha: 0.01
    beta: 95%
  - description: "Experiment with α=0.1 and β=97.5%"
    alpha: 0.1
    beta: 97.5%
  - description: "Experiment with α=0.01 and β=97.5%"
    alpha: 0.01
    beta: 97.5%
```

MetaConfigurations.jl can derive these combinations from a more abstract and comprehensive representation, which we call a meta-configuration:

```
experiments:
  description: "Experiment with α=$alpha and β=$beta"
  alpha:
    - 0.1
    - 0.01
  beta:
    - 95%
    - 97.5%
```

This derivation of combinations is supported for nested properties up to arbitrary levels.
