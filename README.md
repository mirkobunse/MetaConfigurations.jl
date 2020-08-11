[![Build Status](https://travis-ci.org/mirkobunse/MetaConfigurations.jl.svg?branch=master)](https://travis-ci.org/mirkobunse/MetaConfigurations.jl)

A meta-configuration defines a set of configurations as a single, more abstract and comprehensive configuration.

For example, assume you want to describe four experiments, each of which consists of a combination of two parameters.

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

MetaConfigurations.jl can derive these combinations from a more abstract and comprehensive representation, a meta-configuration:

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
