# Imbalance.jl

![Imbalance](https://i.imgur.com/C34ilSZ.png)

A Julia package with resampling methods to correct for class imbalance in a wide variety of classification settings.

[![](https://img.shields.io/badge/docs-dev-blue.svg)]([https://essamwisam.github.io/Imbalance.jl/dev/](https://juliaai.github.io/Imbalance.jl/dev/))
[![Tests](https://github.com/JuliaAI/Imbalance.jl/actions/workflows/Runtests.yml/badge.svg)](https://github.com/JuliaAI/Imbalance.jl/actions/workflows/Runtests.yml)

## ⏬ Installation
```julia
import Pkg;
Pkg.add("Imbalance")
```


## 🚀 Quick Start
We will illustrate using the package to oversample with`SMOTE`; however, all other implemented oversampling methods follow the same pattern.

### 🔵 Standard API
All methods by default support a pure functional interface.
```julia
using Imbalance

# Set dataset properties then generate imbalanced data
probs = [0.5, 0.2, 0.3]                  # probability of each class      
num_rows, num_continuous_feats = 100, 5
X, y = generate_imbalanced_data(num_rows, num_continuous_feats; probs, rng=42)      

# Apply SMOTE to oversample the classes
Xover, yover = smote(X, y; k=5, ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)

```

### 🤖 MLJ Interface
All methods support the `MLJ` interface over tables where instead of directly calling the method, one instantiates a model for the method while optionally passing the keyword parameters found in the functional interface then wraps the model in a `machine` and follows by calling `transform` on the machine and data.
```julia
using MLJ

# Load the model
SMOTE = @load SMOTE pkg=Imbalance

# Create an instance of the model 
oversampler = SMOTE(k=5, ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)

# Wrap it in a machine
mach = machine(oversampler)

# Provide the data to transform 
Xover, yover = transform(mach, X, y)
```
All implemented oversampling methods are considered static transforms and hence, no `fit` is required. 

### 🏓 Table Transforms Interface
This interface operates on single tables; it assumes that `y` is one of the columns of the given table. Thus, it follows a similar pattern to the `MLJ` interface except that the index of `y` is a required argument while instantiating the model and the data to be transformed via `apply` is only one table `Xy`.
```julia
using Imbalance
using Imbalance.TableTransforms

# Generate imbalanced data
num_rows = 200
num_features = 5
y_ind = 3
Xy, _ = generate_imbalanced_data(num_rows, num_features; 
                                 probs=[0.5, 0.2, 0.3], insert_y=y_ind, rng=42)

# Initiate SMOTE model
oversampler = SMOTE(y_ind; k=5, ratios=Dict(0=>1.0, 1=> 0.9, 2=>0.8), rng=42)
Xyover = Xy |> oversampler       # can chain with other table transforms                  
Xyover, cache = TableTransforms.apply(oversampler, Xy)    # equivalently
```
The `reapply(oversampler, Xy, cache)` method from `TableTransforms` simply falls back to `apply(oversample, Xy)` and the `revert(oversampler, Xy, cache)` reverts the transform by removing the oversampled observations from the table.


## 🎨 Features
- Provides some of the most sought oversampling algorithms in machine learning and is still under development
- Supports multi-class classification and both nominal and continuous features
- Generic by supporting table input/output formats as well as matrices
- Provides `MLJ` and `TableTransforms` interfaces aside from the default pure functional interface
- Supports tables regardless to whether the target is a separate column or one of the columns
- Supports automatic encoding and decoding of nominal features


## 📝 Methods

The package so far provides five oversampling algorithms that all work in multi-class settings and with options for handling continuous and nominal features. In particular, it implements:

* Basic Random Oversampling 
* Random Oversampling Examples (ROSE)
* Synthetic Minority Oversampling Technique (SMOTE)
* SMOTE-Nominal (SMOTE-N)
* SMOTE-Nominal Categorical (SMOTE-NC)


## 📜 Rationale
Most if not all machine learning algorithms can be viewed as a form of empirical risk minimization where the object is to find the parameters $\theta$ that for some loss function $L$ minimize 

$$\hat{\theta} = \arg\min_{\theta} \frac{1}{N} \sum_{i=1}^{N} L(f_{\theta}(x_i), y_i)$$

The underlying assumption is that minimizing this empirical risk corresponds to approximately minimizing the true risk which considers all examples in the populations which would imply that $f_\theta$ is approximately the true target function $f$ that we seek to model.

In a multi-class setting with $K$ classes, one can write

$$\hat{\theta} = \arg\min_{\theta} \left( \frac{1}{N_1} \sum_{i \in C_1} L(f_{\theta}(x_i), y_i) + \frac{1}{N_2} \sum_{i \in C_2} L(f_{\theta}(x_i), y_i) + \ldots + \frac{1}{N_K} \sum_{i \in C_K} L(f_{\theta}(x_i), y_i) \right)$$

Class imbalance occurs when some classes have much fewer examples than other classes. In this case, the corresponding terms contribute minimally to the sum which makes it easier for any learning algorithm to find an approximate solution to the empirical risk that mostly only minimizes the over the significant sums. This yields a hypothesis $f_\theta$ that may be very different from the true target $f$ with respect to the minority classes which may be the most important for the application in question.

One obvious possible remedy is to weight the smaller sums so that a learning algorithm more easily avoids approximate solutions that exploit their insignificance which can be seen to be equivalent to repeating examples of the observations in minority classes. This can be achieved by naive random oversampling which is offered by this package along with other more advanced oversampling methods.

To our knowledge, there are no existing maintained Julia packages that implement oversampling algorithms for multi-class classification problems or that handle both nominal and continuous features. This has served as a primary motivation for the creation of this package.

## 👥 Credits
This package was created by [Essam Wisam](https://github.com/JuliaAI) as a Google Summer of Code project, under the mentorship of [Anthony Blaom](https://ablaom.github.io). Additionally, [Rik Huijzer](https://github.com/rikhuijzer) and his binary `SMOTE` implementation in `Resample.jl` have also been helpful.
