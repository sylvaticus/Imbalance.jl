# this tests the utils file. check test_utils for utility functions used in testing
using Imbalance: tablify, get_class_counts, group_lengths, group_inds, randcols, rng_handler, ERR_MISSING_CLASS, ERR_INVALID_RATIO, WRN_UNDERSAMPLE, ERR_TABLE_TYPE

@testset "tablify throws error" begin
    @test_throws ERR_TABLE_TYPE("Int64") begin
        f(x) = x
        tablify(f, 1, [1, 2, 3])
    end
end


@testset "get_class_counts" begin
    @testset "Equalize classes" begin
        y = [1, 1, 2, 3, 3, 3]          # majority has 3 observations
        expected_needed_counts = Dict(1 => 1, 2 => 2, 3 => 0)
        counts = get_class_counts(y)
        @test counts == expected_needed_counts
    end
    
    @testset "Error Tests" begin
        # Test for missing class in ratios
        @test_throws ERR_MISSING_CLASS(3) begin
            y = [1, 2, 3]
            ratios = Dict(1 => 0.9, 2 => 0.9)
            get_class_counts(y, ratios)
        end

        # Test for invalid ratio (non-positive)
        @test_throws ERR_INVALID_RATIO(2) begin
            y = [1, 2, 3]
            ratios = Dict(1 => 0.9, 2 => -0.9, 3 => 0.9)
            get_class_counts(y, ratios)
        end

        @test_logs (:warn, WRN_UNDERSAMPLE(0.5, 1, -1, 1.0)) begin
            y = [1,1,1,2,2,2]
            ratios = Dict(1=>0.5, 2=>1.0)
            get_class_counts(y, ratios)
        end
    end

    @testset "Specify ratios with a dictionary" begin
        y = [1, 1, 2, 3, 3, 4]           # majority has 2 observations
        ratios = Dict(1 => 2.0, 2 => 1.5, 3 => 1.0, 4 => 1.0)        
        expected_needed_counts = Dict(1 => 2, 2 => 2, 3 => 0, 4 => 1)
        counts = get_class_counts(y, ratios)
        @test counts == expected_needed_counts
    end
    
    @testset "Specify ratios with a float" begin
        y = [1, 1, 2, 3, 3, 3, 3]       # majority has 4 observations
        ratio = 1.5
        expected_needed_counts = Dict(1 => 4, 2 => 5, 3 => 2)
        counts = get_class_counts(y, ratio)
        @test counts == expected_needed_counts
    end
end


@testset "randcols" begin
    rng = StableRNG(1234)     
    X = [1 2; 3 4; 5 6] # create a 3x2 matrix
    @test randcols(rng, X) in [[1, 3, 5], [2, 4, 6]] 
end


@testset "randcols" begin
    rng = StableRNG(1234) 
    X = [1 2; 3 4; 5 6]
    @test randcols(rng, X, 2)[:, 1] in [[1, 3, 5], [2, 4, 6]] 
    @test randcols(rng, X, 2)[:, 2] in [[1, 3, 5], [2, 4, 6]] 
end


@testset "group_inds" begin
    categorical_array = ["a", "b", "a", "c", "b"] 
    @test group_inds(categorical_array) == Dict("a" => [1, 3], "b" => [2, 5], "c" => [4]) 
end


@testset "group_lengths" begin
    categorical_array = ["a", "b", "a", "c", "b"] 
    @test group_lengths(categorical_array) == Dict("a" => 2, "b" => 2, "c" => 1) 
end


# compare rng_handler(rng::Integer) = StableRNG(rng) with rng_handler(rng::AbstractRNG) = rng
@testset "rng_handler" begin
    @test rng_handler(1234) == rng_handler(StableRNG(1234))
end