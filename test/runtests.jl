using MetaConfigurations, OrderedCollections, Test

# expand the properties 'array' and 'complexarray' in the test configuration
c = MetaConfigurations.parsefile("test.yml") # load the test file
@test typeof(c["array"]) <: Array
@test eltype(c["array"]) <: Int
@test typeof(c["complexarray"]) <: Array
@test eltype(c["complexarray"]) == Dict{String,Any}

function testexpansion(c::Dict{String,Any}, expand::String, remain::String)
    if (!(typeof(c[expand]) <: Array)) error("Only array properties can be tested!") end
    ce = MetaConfigurations.expand(c, expand)
    @test typeof(ce) <: Array             # expansion was performed
    @test length(ce) == length(c[expand]) # length of expansion is correct
    @test eltype(ce) == typeof(c)         # types are stable
    for cei in ce
        # individual values of expanded property are stored as property values
        @test typeof(cei[expand]) == eltype(c[expand])
        # remaining config is untouched
        @test cei[remain] == c[remain]
    end
end
testexpansion(c, "array", "complexarray")
testexpansion(c, "complexarray", "array")

# ensure that the expansion is free of side effects
c = Dict{Symbol,Any}(
    :expansion => [true, false], # we will expand on this value
    :outer => Dict{Symbol,Any}(
        :inner => "foo" # and we will replace this value
    )
)
ce = MetaConfigurations.expand(c, :expansion)
ce[1][:outer][:inner] = "bar" # set value
@test ce[2][:outer][:inner] == "foo" # check absence of side effects

# test patching
p = MetaConfigurations.parsefile("test.yml")
c = MetaConfigurations.patch(
    p,
    a = 3,
    b = "5",
    c = [1, 2, 3]
)
@test c["a"] == 3
@test c["b"] == "5"
@test c["c"] == [1, 2, 3]
@test typeof(c) == typeof(p)

# ...and the same with Symbol keys
p = MetaConfigurations.parsefile("test.yml", dicttype=Dict{Symbol, Any})
c = MetaConfigurations.patch(
    p,
    a = 3,
    b = "5",
    c = [1, 2, 3]
)
@test typeof(c) == typeof(p)
@test c[:a] == 3
@test c[:b] == "5"
@test c[:c] == [1, 2, 3]

# ...and for maintaining value types
p = Dict{Symbol, Any}(:foo => [1, 2], :bar => [3, 4]) # explicit Any instead of Vector{Int64}
c = MetaConfigurations.patch(
    p,
    bat = [0, 0, 0]
)
@test typeof(c) == typeof(p)

# ...and with other Dict types
p = MetaConfigurations.parsefile("test.yml", dicttype=OrderedDict{Symbol, Any})
c = MetaConfigurations.patch(
    p,
    a = 3,
    b = "5",
    c = [1, 2, 3]
)
@test typeof(c) == typeof(p)

# test writing to files by parsing and checking the output
c = MetaConfigurations.parsefile("test.yml")
t = tempname()
@testset for filename in ["$t.yml", "$t.yaml", "$t.json"]
    MetaConfigurations.save(filename, c) # write to a temporary file
    parsed = MetaConfigurations.parsefile(filename)
    @test parsed == c
    @test typeof(MetaConfigurations.parsefile(
        filename; dicttype=Dict{Symbol,Any})
    ) == Dict{Symbol,Any} # test parsing of another dicttype
    rm(filename) # cleanup
end

# test sub-expansion
c = MetaConfigurations.parsefile("test.yml")
ce = MetaConfigurations.expand(c, ["subexpand", "y"])
@test typeof(ce) <: Array
@test length(ce) == length(c["subexpand"]["y"])
@test eltype(ce) == typeof(c)
for cei in ce
    @test typeof(cei["subexpand"]["y"]) == eltype(c["subexpand"]["y"])
    @test typeof(cei["subexpand"]) == typeof(c)
end

c = MetaConfigurations.parsefile("test.yml")
ce = MetaConfigurations.expand(c, ["subexpandlist", "y"])
@test typeof(ce) <: Array
@test length(ce) == length(c["subexpandlist"][1]["y"]) + 1 # +1 because 'nothing' in item 2
for cei in ce
    @test typeof(cei["subexpandlist"][1]["y"]) <: Union{eltype(c["subexpandlist"][1]["y"]), Nothing}
end

# test property interpolation
c = MetaConfigurations.parsefile("test.yml")
@test MetaConfigurations.interpolate(c, "inter") == "blaw-blaw"
@test MetaConfigurations.interpolate(c, "multi") == "blaw-blaw-blaw"
@test_throws ErrorException MetaConfigurations.interpolate(c, "kwarg") # argument missing
@test MetaConfigurations.interpolate(c, "kwarg", arg="X") == "blaw-X"

# in-place interpolation
@test c["inter"] == "blaw-\$(simple)" # the above interpolation is not taken out in-place
MetaConfigurations.interpolate!(c, "inter")
@test c["inter"] == "blaw-blaw" # now it is
@test typeof(c) == typeof(MetaConfigurations.parsefile("test.yml")) # test type stability

# interpolation with keys of type Symbol
c = MetaConfigurations.parsefile("test.yml"; dicttype=Dict{Symbol,Any})
@test MetaConfigurations.interpolate(c, :inter) == "blaw-blaw"
@test MetaConfigurations.interpolate(c, :multi) == "blaw-blaw-blaw"
@test_throws ErrorException MetaConfigurations.interpolate(c, :kwarg)
@test MetaConfigurations.interpolate(c, :kwarg, arg="X") == "blaw-X"
@test c[:inter] == "blaw-\$(simple)"
MetaConfigurations.interpolate!(c, :inter)
@test c[:inter] == "blaw-blaw"
@test typeof(c) == typeof(MetaConfigurations.parsefile("test.yml"; dicttype=Dict{Symbol,Any}))

# test the find function
c = MetaConfigurations.parsefile("test.yml")
r = MetaConfigurations.find(c["find_integer"], "findme")
@test eltype(r) <: Integer
@test 1 in r
@test 2 in r
@test length(r) == 2

c = MetaConfigurations.parsefile("test.yml", dicttype=Dict{Symbol, Any})
r = MetaConfigurations.find(c[:find_any], :findme)
@test eltype(r) == Any
@test 1 in r
@test Dict{Symbol, Any}(:a => 1, :b => 2) in r
@test length(r) == 2
