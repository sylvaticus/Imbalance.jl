
### SMOTE with MLJ Interface

mutable struct SMOTE{T,R<:Union{Integer,AbstractRNG}, I<:Integer} <: Static
    k::I
    ratios::T
    rng::R
    try_preserve_type::Bool
end;



"""
Check whether the given model hyperparameters are valid and clean them if necessary. 
"""
function MMI.clean!(s::SMOTE)
    message = ""
    if s.k < 1
        throw(ArgumentError(ERR_NONPOS_K(s.k)))
    end
    return message
end




"""
Initiate a SMOTE model with the given hyper-parameters.
"""
function SMOTE(;
    k::Integer = 5,
    ratios::Union{Nothing,AbstractFloat,Dict{T,<:AbstractFloat}} = 1.0,
    rng::Union{Integer,AbstractRNG} = default_rng(), try_preserve_type::Bool=true
) where {T}
    model = SMOTE(k, ratios, rng, try_preserve_type)
    MMI.clean!(model)
    return model
end

"""
Oversample data X, y using SMOTE
"""
function MMI.transform(s::SMOTE, _, X, y)
    smote(X, y; k = s.k, ratios = s.ratios, rng = s.rng, 
        try_preserve_type = s.try_preserve_type)
end
function MMI.transform(s::SMOTE, _, X::AbstractMatrix{<:Real}, y)
    smote(X, y; k = s.k, ratios = s.ratios, rng = s.rng)
end


MMI.metadata_pkg(
    SMOTE,
    name = "Imbalance",
    package_uuid = "c709b415-507b-45b7-9a3d-1767c89fde68",
    package_url = "https://github.com/JuliaAI/Imbalance.jl",
    is_pure_julia = true,
)

MMI.metadata_model(
    SMOTE,
    input_scitype = Union{Table(Continuous),AbstractMatrix{Continuous}},
    output_scitype = Union{Table(Continuous),AbstractMatrix{Continuous}},
    target_scitype = AbstractVector,
    load_path = "Imbalance.MLJ.SMOTE"
)
function MMI.transform_scitype(s::SMOTE)
    return Tuple{
        Union{Table(Continuous),AbstractMatrix{Continuous}},
        AbstractVector{<:Finite},
    }
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


# Hyperparameters

- `k=5`: Number of nearest neighbors to consider in the SMOTE algorithm.  Should be within
    the range `[1, n - 1]`, where `n` is the number of observations; otherwise set to the
    nearest of these two values.

$((COMMON_DOCS["RATIOS"]))

$((COMMON_DOCS["RNG"]))

# Transform Inputs

$((COMMON_DOCS["INPUTS"]))

# Transform Outputs

$((COMMON_DOCS["OUTPUTS"]))

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