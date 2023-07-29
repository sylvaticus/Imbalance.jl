"""
Assuming that all the observations in the observation matrix X belong to the same class, 
generate n new observations for that class using ROSE.

# Arguments
- `X::AbstractMatrix`: A matrix where each row is an observation of floats
- `n::Int`: Number of new observations to generate
- `s::float`: A parameter that proportionally controls the bandwidth of the Gaussian kernel
- `rng::AbstractRNG`: Random number generator

# Returns
- `AbstractMatrix`: A matrix where each row is a new observation generated by ROSE
"""
function rose_per_class(
    X::AbstractMatrix{<:AbstractFloat}, n::Int; 
    s::AbstractFloat=1.0,  rng::AbstractRNG=default_rng()
)
    # sample n rows from X
    Xnew = randcols(rng, X, n)
    # For s == 0 this is just random oversampling
    if s == 0.0 return Xnew end
    # compute the standard deviation column-wise
    σs = vec(std(Xnew, dims=1))
    d = size(Xnew, 1)
    N = size(Xnew, 2)
    h = (4/((d+2)*N))^(1/(d+4))
    # make a diagonal matrix of the result
    H = Diagonal(σs * s * h)
    # generate standard normal samples of same dimension of Xnew
    XSnew = randn(rng, size(Xnew))
    # matrix multiply the diagonal matrix by XSnew
    XSnew =  XSnew * H
    # add Xnew and XSnew
    Xnew += XSnew
    # return the result
    return Xnew
end

"""
    rose(
        X, y; 
        s::AbstractFloat=0.1, ratios=nothing, rng::AbstractRNG=default_rng()
    )

Oversample a dataset given by a matrix or table of observations X and an abstract
vector of labels y using ROSE.

$DOC_MAIN_ARGUMENTS
- `s::float`: A parameter that proportionally controls the bandwidth of the Gaussian kernel
$DOC_RATIOS_ARGUMENT
$DOC_RNG_ARGUMENT

$DOC_RETURNS
"""
function rose(
    X::AbstractMatrix{<:AbstractFloat}, y::AbstractVector; 
    s::AbstractFloat=0.1, ratios=nothing, rng::Union{AbstractRNG, Integer}=default_rng()
)
    rng = rng_handler(rng)
    Xover, yover = generic_oversample(X, y, rose_per_class; s, ratios, rng)
    return Xover, yover
end

function rose(
    X, y::AbstractVector; 
    s::AbstractFloat=0.1, ratios=nothing, rng::Union{AbstractRNG, Integer}=default_rng()
)
    Xover, yover = tablify(rose, X, y; s, ratios, rng)
    return Xover, yover
end