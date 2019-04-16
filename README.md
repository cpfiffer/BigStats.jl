# BigStats.jl

Does giant regressions and stuff without sticking 89gb of data or whatever on your RAM. Currently only does regressions by iterating row-wise rather than doing that whole `inv(x'x)*x'y` thing. Also more flexible than the [OnlineStats](https://github.com/joshday/OnlineStats.jl) regressions.

Here's how it works:

```julia
using BigStats, JuliaDB

# Use JuliaDB to load a bajillion csv files
df = loadtable("all/those/damn/files.csv")
```
```
Table with 150000 rows, 3 columns:
x        z         y
──────────────────────────
4.78379  0.888879  24.2974
4.90351  1.48536   24.31
5.32036  1.178     25.3493
7.63348  0.821962  28.3031
4.09702  0.664722  22.4701
6.71601  1.25141   28.2858
5.33011  0.545176  24.4669
⋮
3.85347  1.00619   22.5686
5.1367   0.973969  22.6513
6.45745  1.11975   26.754
5.41692  1.43157   26.7851
5.1201   1.15876   24.8335
```

```julia
# Make some lagged variables or whatever
lagged_df = lag(df, (:y, :x), lengths=[1,2,3])
```
```
Table with 150000 rows, 9 columns:
x        z         y        y_lag_1  x_lag_1  y_lag_2  x_lag_2  y_lag_3  x_lag_3
────────────────────────────────────────────────────────────────────────────────
4.78379  0.888879  24.2974  missing  missing  missing  missing  missing  missing
4.90351  1.48536   24.31    24.2974  4.78379  missing  missing  missing  missing
5.32036  1.178     25.3493  24.31    4.90351  24.2974  4.78379  missing  missing
7.63348  0.821962  28.3031  25.3493  5.32036  24.31    4.90351  24.2974  4.78379
4.09702  0.664722  22.4701  28.3031  7.63348  25.3493  5.32036  24.31    4.90351
6.71601  1.25141   28.2858  22.4701  4.09702  28.3031  7.63348  25.3493  5.32036
5.33011  0.545176  24.4669  28.2858  6.71601  22.4701  4.09702  28.3031  7.63348
⋮
3.85347  1.00619   22.5686  25.8175  4.83509  22.9326  4.14523  25.1764  6.26665
5.1367   0.973969  22.6513  22.5686  3.85347  25.8175  4.83509  22.9326  4.14523
6.45745  1.11975   26.754   22.6513  5.1367   22.5686  3.85347  25.8175  4.83509
5.41692  1.43157   26.7851  26.754   6.45745  22.6513  5.1367   22.5686  3.85347
5.1201   1.15876   24.8335  26.7851  5.41692  26.754   6.45745  22.6513  5.1367
```

```julia
# Call BigStats.ols with a StatsModels formula
fitted = ols(@formula(y ~ 1 + x + z + x_lag_1), dropmissing(lagged_df))
```

```julia
# Make another table with residuals added
r = residuals(fitted, dropmissing(m), joined=true)
```
```
Table with 149997 rows, 11 columns:
Columns:
#   colname    type
──────────────────────
1   x          Float64
2   z          Float64
3   y          Float64
4   y_lag_1    Float64
5   x_lag_1    Float64
6   y_lag_2    Float64
7   x_lag_2    Float64
8   y_lag_3    Float64
9   x_lag_3    Float64
10  residuals  Float64
11  predicted  Float64
```
