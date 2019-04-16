module BigStats

using StatsModels
using JuliaDB: rows, insertcol, columns, table, select, pkeys, pushcol
using LinearAlgebra: Symmetric
using NamedTupleTools

import ShiftedArrays
import StatsModels: predict

export ols, predict, residuals, coef

struct OLS
    formula::FormulaTerm
    xx::Array
    xy::Array
    β::Array
    n::Int64

end

function coef(o::OLS)
    return o.β
end

function ols(formula, df)
    if !StatsModels.has_schema(formula)
        formula = apply_schema(formula, schema(formula, df))
    end

    y1 = response(formula, [df[1]])
    x1 = modelmatrix(formula, [df[1]])
    n = 0
    xx = zeros(size(x1'x1))
    xy = zeros(size(x1'y1))
    for i in rows(df)
        xn = modelmatrix(formula, [i])
        yn = response(formula, [i])
        xx += xn'xn
        xy += xn'yn
        n += 1
    end
    b = inv(xx) * xy
    return OLS(formula, xx, xy, b, n)
end

function predict(o::OLS, r::NamedTuple)
    x = modelmatrix(o.formula, [r])
    return x*o.β
end

function predict(o::OLS, r)
    x = modelmatrix(o.formula, r)
    return x*o.β
end

function loss(o::OLS, r::NamedTuple)
    y = response(o.formula, [r])[1]
    xhat = predict(o, r)[1]
    return (residuals = y - xhat, predicted = xhat)
end

function residuals(o::OLS, df; joined = false)
    resid = map(x -> loss(o, x), df)
    if joined
        return table(merge(columns(df), columns(resid)))
    else
        return resid
    end
end

lag(df, syms::Symbol; lengths=[1]) = lag(df, (syms,), lengths=lengths)
function lag(df, syms::Tuple; lengths=[1])
    allcols = []
    for l in lengths
        for s in syms
            new_name = Symbol("$(s)_lag_$l")
            df = pushcol(df, new_name, ShiftedArrays.lag(columns(df, s), l))
        end
    end

    # inds = collect(pkeys(df).x1) .+ amount[1]
    # pop!(inds)
    # selected = select(df[inds], (syms,))
    # missings = if length(syms) == 1
    #     NamedTuple{(syms[1], )}( (missing,))
    # else
    #     [s => missing for s in syms]
    # end
    # missing_row = repeat([missings], amount[1])
    # missing_table = table(missing_row)
    # display(missing_table)
    # display(selected)
    # merge(missing_table, selected)
    return df
end

end # module
