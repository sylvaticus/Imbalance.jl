
# Used by SMOTE and SMOTENC
"""
Generate a new random observation that lies in the line joining the two observations `x₁` and `x₂`

# Arguments
- `x₁`: First observation 
- `x₂`: Second observation 
- `rng`: Random number generator

# Returns
-  New observation `x` as a vector that satisfies `x = (x₂ - x₁) * r + x₁`
    where `r`` is a random number between `0` and `1`
"""
function get_collinear_point(
    x₁::AbstractVector,
    x₂::AbstractVector;
    rng::AbstractRNG = default_rng(),
)
    r = rand(rng)
    # Equivalent to (x₂  .- x₁ ) .* r .+ x₁  but avoids allocating a new vector
    return @. (1 - r) * x₁ + r * x₂
end



# Used by SMOTE, SMOTENC
"""
Randomly return one of the k-nearest neighbor of a given observation `x` from an observations 
matrix `X`

# Arguments
- `X`: A matrix where each column is an observation
- `ind`: index of point for which we need random neighbor
- `knn_map`: A vector of vectors mapping each element in X by index to its nearest neighbors' indices
- `rng`: Random number generator

# Returns
- `x_randneigh`: A random observation from the k-nearest neighbors of x
"""
function get_random_neighbor(
    X::AbstractMatrix{<:Real},
    ind::Integer,
    knn_map;
    rng::AbstractRNG = default_rng(),
)
    # 1. extract the neighbors inds vector and exclude point itself
    ind_neighs = knn_map[ind][2:end]
    # 2. choose a random neighbor index
    ind_rand_neigh = ind_neighs[rand(rng, 1:length(ind_neighs))]
    # 3. return the corresponding point
    x_randneigh = X[:, ind_rand_neigh]
    return x_randneigh
end

"""
Choose a random point from the given observations matrix `X` and generate a new point that 
randomly lies in the line joining the random point and randomly one of its k-nearest neighbors. 

# Arguments
- `X`: A matrix where each column is an observation
- `knn_map`: A vector of vectors mapping each element in X by index to its nearest neighbors' indices
- `rng`: Random number generator

# Returns
- `x_new`: A new observation generated by SMOTE
"""
function generate_new_smote_point(
    X::AbstractMatrix{<:AbstractFloat},
    knn_map;
    rng::AbstractRNG,
)
    # 1. Choose a random point from X (by index)
    ind = rand(rng, 1:size(X, 2))
    x_rand = X[:, ind]
    # 2. Choose a random point from its k-nearest neighbors 
    x_rand_neigh = get_random_neighbor(X, ind, knn_map; rng)
    # 3. Generate a new point that randomly lies in the line between them
    x_new = get_collinear_point(x_rand, x_rand_neigh; rng)
    return x_new
end


# Used by SMOTE, SMOTENC and SMOTEN
"""
This function is only called when n>1 and checks whether 0<k<n or not. If k<0, it throws an error.
and if k>=n, it warns the user and sets k=n-1.

# Arguments
- `k`: Number of nearest neighbors to consider
- `n`: Number of observations

# Returns
-  Number of nearest neighbors to consider

"""
function check_k(k, n_class)
    if k < 1
        throw((ERR_NONPOS_K(k)))
    end
    if k >= n_class
        @warn WRN_K_TOO_BIG(k, n_class)
        k = n_class - 1
    end
    return k
end

"""
Assuming that all the observations in the observation matrix X belong to the same class,
use SMOTE to generate `n` new observations for that class.

# Arguments
- `X`: A matrix where each row is an observation
- `n`: Number of new observations to generate
- `k`: Number of nearest neighbors to consider. Must be less than the 
    number of observations in `X`
- `rng`: Random number generator

# Returns
- `Xnew`: A matrix where each row is a new observation generated by SMOTE
"""
function smote_per_class(
    X::AbstractMatrix{<:AbstractFloat},
    n::Integer;
    k::Integer = 5,
    rng::AbstractRNG = default_rng(),
)
    # Can't draw lines if there are no neighbors
    n_class = size(X, 2)
    n_class == 1 && (@warn WRN_SINGLE_OBS; return Array{Float64}(undef, size(X, 1), 0))

    # Automatically fix k if needed
    k = check_k(k, n_class)

    # Build KDTree for KNN
    tree = KDTree(X)
    knn_map, _ = knn(tree, X, k + 1, true)

    # Generate n new observations
    Xnew = zeros(Float32, size(X, 1), n)
    p = Progress(n)
    for i=1:n
        Xnew[:, i] = generate_new_smote_point(X, knn_map; rng)
        next!(p)
    end
    return Xnew
end


"""
    smote(
        X, y;
        k=5, ratios=1.0, rng=default_rng(),
        try_perserve_type=true
    )

# Description
Oversamples a dataset using `SMOTE` (Synthetic Minority Oversampling Techniques) algorithm to 
    correct for class imbalance as presented in [1]

# Positional Arguments

$(COMMON_DOCS["INPUTS"])

# Keyword Arguments

$(COMMON_DOCS["K"])

$(COMMON_DOCS["RATIOS"])

$(COMMON_DOCS["RNG"])

$(COMMON_DOCS["TRY_PERSERVE_TYPE"])

# Returns

$(COMMON_DOCS["OUTPUTS"])


# Example

```@repl
using Imbalance

# set probability of each class
class_probs = [0.5, 0.2, 0.3]                         
num_rows, num_continuous_feats = 100, 5
# generate a table and categorical vector accordingly
X, y = generate_imbalanced_data(num_rows, num_continuous_feats; 
                                class_probs, rng=42)    

julia> Imbalance.checkbalance(y)
1: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 19 (39.6%) 
2: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 33 (68.8%) 
0: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 48 (100.0%) 

# apply SMOTE
Xover, yover = smote(X, y; k = 5, ratios = Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng = 42)

julia> Imbalance.checkbalance(yover)
2: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 38 (79.2%) 
1: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 43 (89.6%) 
0: ▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 48 (100.0%) 
```

# MLJ Model Interface

Simply pass the keyword arguments while initiating the `SMOTE` model and pass the 
    positional arguments `X, y` to the `transform` method. 

```julia
using MLJ
SMOTE = @load SMOTE pkg=Imbalance

# Wrap the model in a machine
oversampler = SMOTE(k=5, ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)
mach = machine(oversampler)

# Provide the data to transform (there is nothing to fit)
Xover, yover = transform(mach, X, y)
```
You can read more about this `MLJ` interface [here]().



# TableTransforms Interface

This interface assumes that the input is one table `Xy` and that `y` is one of the columns. Hence, an integer `y_ind`
    must be specified to the constructor to specify which column `y` is followed by other keyword arguments. 
    Only `Xy` is provided while applying the transform.

```julia
using Imbalance
using Imbalance.TableTransforms

# Generate imbalanced data
num_rows = 200
num_features = 5
y_ind = 3
Xy, _ = generate_imbalanced_data(num_rows, num_features; 
                                 class_probs=[0.5, 0.2, 0.3], insert_y=y_ind, rng=42)

# Initiate SMOTE model
oversampler = SMOTE(y_ind; k=5, ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)
Xyover = Xy |> oversampler                              
# equivalently if TableTransforms is used
Xyover, cache = TableTransforms.apply(oversampler, Xy)    # equivalently
```
The `reapply(oversampler, Xy, cache)` method from `TableTransforms` simply falls back to `apply(oversample, Xy)` and the `revert(oversampler, Xy, cache)`
reverts the transform by removing the oversampled observations from the table.

# Illustration
A full basic example along with an animation can be found [here](https://githubtocolab.com/JuliaAI/Imbalance.jl/blob/dev/examples/oversample_smote.ipynb). 
    You may find more practical examples in the [walkthrough](https://juliaai.github.io/Imbalance.jl/dev/examples/) 
    section which also explains running code on Google Colab.

# References
[1] N. V. Chawla, K. W. Bowyer, L. O.Hall, W. P. Kegelmeyer,
“SMOTE: synthetic minority over-sampling technique,”
Journal of artificial intelligence research, 321-357, 2002.
"""
function smote(
    X::AbstractMatrix{<:AbstractFloat},
    y::AbstractVector;
    k::Integer = 5,
    ratios = 1.0,
    rng::Union{AbstractRNG,Integer} = default_rng(),
    try_perserve_type::Bool = true,
)
    rng = rng_handler(rng)
    Xover, yover = generic_oversample(X, y, smote_per_class; ratios, k, rng)
    return Xover, yover
end

# dispatch for table inputs
function smote(
    X,
    y::AbstractVector;
    k::Integer = 5,
    ratios = 1.0,
    rng::Union{AbstractRNG,Integer} = default_rng(),
    try_perserve_type::Bool = true,
)
    Xover, yover = tablify(smote, X, y;try_perserve_type=try_perserve_type,  k, ratios, rng)
    return Xover, yover
end

# dispatch for table inputs where y is one of the columns
function smote(
    Xy,
    y_ind::Integer;
    k::Integer = 5,
    ratios = 1.0,
    rng::Union{AbstractRNG,Integer} = default_rng(),
    try_perserve_type::Bool = true,
)
    Xyover = tablify(smote, Xy, y_ind; try_perserve_type=try_perserve_type, k, ratios, rng)
    return Xyover
end
