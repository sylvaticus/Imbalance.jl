# this tests the utils file. check test_utils for utility functions used in testing
using Imbalance: get_class_counts, group_lens, group_inds, randrows


@testset "get_class_counts" begin
    @testset "Equalize classes" begin
        y = [1, 1, 2, 3, 3, 3]          # majority has 3 observations
        expected_needed_counts = Dict(1 => 1, 2 => 2, 3 => 0)
        counts = get_class_counts(y)
        @test counts == expected_needed_counts
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


@testset "randrows" begin
    rng = MersenneTwister(1234)     
    X = [1 2; 3 4; 5 6] # create a 3x2 matrix
    @test randrows(rng, X) in [[1, 2], [3, 4], [5, 6]] 
end


@testset "randrows" begin
    rng = MersenneTwister(1234) 
    X = [1 2; 3 4; 5 6] 
    @test randrows(rng, X, 2)[1, :] in [[1, 2], [3, 4], [5, 6]] 
    @test randrows(rng, X, 2)[2, :] in [[1, 2], [3, 4], [5, 6]] 
end


@testset "group_inds" begin
    categorical_array = ["a", "b", "a", "c", "b"] 
    @test group_inds(categorical_array) == Dict("a" => [1, 3], "b" => [2, 5], "c" => [4]) 
end


@testset "group_lens" begin
    categorical_array = ["a", "b", "a", "c", "b"] 
    @test group_lens(categorical_array) == Dict("a" => 2, "b" => 2, "c" => 1) 
end
