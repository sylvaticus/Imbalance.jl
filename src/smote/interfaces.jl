### SMOTE TableTransforms Interface

struct SMOTE_t{T} <: TransformsBase.Transform
    y_ind::Integer
    k::Integer
    ratios::T
    rng::Union{Integer,AbstractRNG}
end

TransformsBase.isrevertible(::Type{SMOTE_t}) = true
TransformsBase.isinvertible(::Type{SMOTE_t}) = false

"""
Instantiate a SMOTE table transform

# Arguments

- `y_ind::Integer`: The index of the column containing the labels (integer-code) in the table
- `k::Integer`: Number of nearest neighbors to consider in the SMOTE algorithm. 
    Should be within the range `[1, size(X, 1) - 1]` else set to the nearest of these two values.
$(DOC_RATIOS_ARGUMENT)
$(DOC_RNG_ARGUMENT)

# Returns

- `model::SMOTE_t`: A SMOTE table transform that can be used like other transforms in TableTransforms.jl

"""
SMOTE_t(
    y_ind::Integer;
    k::Integer = 5,
    ratios::Union{Nothing,AbstractFloat,Dict{T,<:AbstractFloat}} = nothing,
    rng::Union{Integer,AbstractRNG} = 123,
) where {T} = SMOTE_t(y_ind, k, ratios, rng)


"""
Apply the SMOTE transform to a table Xy

# Arguments

- `s::SMOTE_t`: A SMOTE table transform

- `Xy::AbstractTable`: A table where each row is an observation

# Returns

- `Xyover::AbstractTable`: A table with both the original and new observations due to SMOTE
- `cache`: A cache that can be used to revert the oversampling
"""
function TransformsBase.apply(s::SMOTE_t, Xy)
    Xyover = smote(Xy, s.y_ind; k = s.k, ratios = s.ratios, rng = s.rng)
    cache = rowcount(Xy)
    return Xyover, cache
end


"""
Revert the oversampling done by SMOTE by removing the new observations

# Arguments

- `s::SMOTE_t`: A SMOTE table transform
- `Xyover::AbstractTable`: A table with both the original and new observations due to SMOTE
- `cache`: cache returned from `apply`

# Returns

- `Xy::AbstractTable`: A table with the original observations only
"""
TransformsBase.revert(::SMOTE_t, Xyover, cache) = revert_oversampling(Xyover, cache)

"""
Equivalent to `apply(s, Xy)`
"""
TransformsBase.reapply(s::SMOTE_t, Xy, cache) = TransformsBase.apply(s, Xy)



### SMOTE with MLJ Interface

mutable struct SMOTE{T} <: Static
    k::Integer 
    ratios::T
    rng::Union{Integer,AbstractRNG}
end;

function MMI.clean!(s::SMOTE)
  message = ""
    if s.k < 1
        message = "k for SMOTE must be at least 1 but found $(s.k). Setting k = 1."
        s.k = 1
    end
    return message
end

function SMOTE(; k::Integer = 5, 
        ratios::Union{Nothing,AbstractFloat,Dict{T,<:AbstractFloat}} = nothing, 
        rng::Union{Integer,AbstractRNG} = default_rng()
) where {T}
    model = SMOTE(k, ratios, rng)
    message = MMI.clean!(model)
    isempty(message) || @warn message
    return model
end


function MMI.transform(s::SMOTE, _, X, y)
    smote(X, y; k = s.k, ratios = s.ratios, rng = s.rng)
end



"""
$(MMI.doc_header(SMOTE))

`SMOTE` implements the SMOTE algorithm to correct for class imbalance as in
N. V. Chawla, K. W. Bowyer, L. O.Hall, W. P. Kegelmeyer,
“SMOTE: synthetic minority over-sampling technique,”
Journal of artificial intelligence research, 321-357, 2002.


# Training data

In MLJ or MLJBase, wrap the model in a machine by

    mach = machine(model)

There is no need to provide any data here because the model is a static transformer.

Likewise, there is no need to `fit!(mach)`.

For default values of the hyper-parameters, model can be constructed by

    model = SMOTE()


# Hyper-parameters

- `k=5`: Number of nearest neighbors to consider in the SMOTE algorithm.  Should be within
    the range `[1, n - 1]`, where `n` is the number of observations; otherwise set to the
    nearest of these two values.

$(DOC_RATIOS_ARGUMENT)

$(DOC_RNG_ARGUMENT)

# Transform Inputs

$(DOC_COMMON_INPUTS)

# Transform Outputs

$(DOC_COMMON_OUTPUTS)

# Operations

- `transform(mach, X, y)`: resample the data `X` and `y` using SMOTE, returning both the
  new and original observations


# Example

```
using MLJ
import Random.seed!
using MLUtils
import StatsBase.countmap

seed!(12345)

# Generate some imbalanced data:
X, y = @load_iris # a table and a vector
rand_inds = rand(1:150, 30)
X, y = getobs(X, rand_inds), y[rand_inds]

julia> countmap(y)
Dict{CategoricalArrays.CategoricalValue{String, UInt32}, Int64} with 3 entries:
  "virginica"  => 12
  "versicolor" => 5
  "setosa"     => 13

# load SMOTE model type:
SMOTE = @load SMOTE pkg=Imbalance

# Oversample the minority classes to  sizes relative to the majority class:
smote = SMOTE(k=10, ratios=Dict("setosa"=>1.0, "versicolor"=> 0.8, "virginica"=>1.0), rng=42)
mach = machine(smote)
Xover, yover = transform(mach, X, y)

julia> countmap(yover)
Dict{CategoricalArrays.CategoricalValue{String, UInt32}, Int64} with 3 entries:
  "virginica"  => 13
  "versicolor" => 10
  "setosa"     => 13
```

"""
SMOTE
