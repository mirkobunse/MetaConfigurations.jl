using MetaConfigurations, Test

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
    for cei in ce
        # individual values of expanded property are stored as property values
        @test typeof(cei[expand]) == eltype(c[expand])
        # remaining config is untouched
        @test cei[remain] == c[remain]
    end
end
testexpansion(c, "array", "complexarray")
testexpansion(c, "complexarray", "array")

# test patching
c = MetaConfigurations.patch(
    MetaConfigurations.parsefile("test.yml"),
    a = 3,
    b = "5",
    c = [1, 2, 3]
)
@test c["a"] == 3
@test c["b"] == "5"
@test c["c"] == [1, 2, 3]

# test writing to files by parsing and checking the output
c = MetaConfigurations.parsefile("test.yml")
@testset for extension in [".yml", ".yaml", ".json"]
    filename = tempname() * extension
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
for cei in ce
    @test typeof(cei["subexpand"]["y"]) == eltype(c["subexpand"]["y"])
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
