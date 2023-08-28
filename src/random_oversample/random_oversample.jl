"""
Assuming that all the observations in the observation matrix X belong to the same class, 
generate n new observations for that class using random oversampling

# Arguments
- `X::AbstractMatrix`: A matrix where each row is an observation of floats
- `n::Int`: Number of new observations to generate

# Returns
- `AbstractMatrix`: A matrix where each column is a new observation generated by ROSE
"""
function random_oversample_per_class(
    X::AbstractMatrix{<:Real},
    n::Int;
    rng::AbstractRNG = default_rng(),
)
    # sample n rows from X
    Xnew = randcols(rng, X, n)
    return Xnew
end

"""
    random_oversample(
        X, y; 
        ratios=nothing, rng=default_rng(), 
        try_preserve_type=true
    )


# Description

Naively oversample a dataset by randomly repeating existing observations with replacement.

# Positional Arguments

$DOC_COMMON_INPUTS

# Keyword Arguments

$DOC_RATIOS_ARGUMENT

$DOC_RNG_ARGUMENT

$DOC_TRY_PERSERVE_ARGUMENT

# Returns

$DOC_COMMON_OUTPUTS


# Example
```julia
using Imbalance
using StatsBase

# set probability of each class
probs = [0.5, 0.2, 0.3]                         
num_rows, num_cont_feats = 100, 5
# generate a table and categorical vector accordingly
X, y = generate_imbalanced_data(num_rows, num_cont_feats; 
                                probs, rng=42)                       
StatsBase.countmap(y)

julia> Dict{CategoricalArrays.CategoricalValue{Int64, UInt32}, Int64} with 3 entries:
0 => 48
2 => 33
1 => 19

# apply random oversampling
Xover, yover = random_oversample(X, y; ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)
StatsBase.countmap(yover)

julia> Dict{CategoricalArrays.CategoricalValue{Int64, UInt32}, Int64} with 3 entries:
0 => 48
2 => 38
1 => 43
```

# MLJ Model Interface

Simply pass the keyword arguments while initiating the `RandomOversampler` model and pass the 
    positional arguments to the `transform` method. 

```julia
using MLJ
RandomOversampler = @load RandomOversampler pkg=Imbalance

# Wrap the model in a machine
oversampler = RandomOversampler(ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)
mach = machine(oversampler)

# Provide the data to transform (there is nothing to fit)
Xover, yover = transform(mach, X, y)
```
The `MLJ` interface is only supported for table inputs. Read more about the interface [here]().

# TableTransforms Interface

This interface assumes that the input is one table `Xy` and that `y` is one of the columns. Hence, an integer `y_ind`
    must be specified to the constructor to specify which column `y` is followed by other keyword arguments. 
    Only `Xy` is provided while applying the transform.

```julia
using Imbalance
using TableTransforms

# Generate imbalanced data
num_rows = 100
num_features = 5
y_ind = 3
Xy, _ = generate_imbalanced_data(num_rows, num_features; 
                                 probs=[0.5, 0.2, 0.3], insert_y=y_ind, rng=42)

# Initiate Random Oversampler model
oversampler = RandomOversampler_t(y_ind; ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)
Xyover = Xy |> oversampler                    
Xyover, cache = TableTransforms.apply(oversampler, Xy)    # equivalently
```
The `reapply(oversampler, Xy, cache)` method from `TableTransforms` simply falls back to `apply(oversample, Xy)` and the `revert(oversampler, Xy, cache)`
reverts the transform by removing the oversampled observations from the table.
"""
function random_oversample(
    X::AbstractMatrix{<:Real},
    y::AbstractVector;
    ratios = 1.0,
    rng::Union{AbstractRNG,Integer} = default_rng(),
)
    rng = rng_handler(rng)
    Xover, yover = generic_oversample(X, y, random_oversample_per_class; ratios, rng,)
    return Xover, yover
end

# dispatch for when X is a table
function random_oversample(
    X,
    y::AbstractVector;
    ratios = 1.0,
    rng::Union{AbstractRNG,Integer} = default_rng(),
    try_perserve_type::Bool=true
)
    Xover, yover = tablify(random_oversample, X, y; 
                           try_perserve_type=try_perserve_type, 
                           encode_func = generic_encoder,
                           decode_func = generic_decoder,
                           ratios, 
                           rng)
    return Xover, yover
end




# dispatch for table inputs where y is one of the columns
function random_oversample(
    Xy,
    y_ind::Integer;
    ratios = 1.0,
    rng::Union{AbstractRNG,Integer} = default_rng(),
    try_perserve_type::Bool=true
)
    Xyover = tablify(random_oversample, Xy, y_ind; 
                    try_perserve_type=try_perserve_type, 
                    encode_func = generic_encoder,
                    decode_func = generic_decoder,
                    ratios, rng)
    return Xyover
end
