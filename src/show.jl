struct ShowVars
end

# Hidden by default
Base.show(io::IO, shown::ShowVars) = nothing

"""
    @shown var1 [var2 ...]

Like `@show`, but sends the variables `var1, ...` to the logging system via
`@info`, with a message of `ShowVars()`. Logging backends can use the
`ShowVars` type to match if necessary.

# Examples

```jldoctest
julia> x = 2
       some_var = [1 2; 3 4]
       @shown x 2*x+4 y=some_var
┌ Info:
│   x = 2
│   2x + 4 = 8
│   y =
│    2×2 Array{Int64,2}:
│     1  2
└     3  4
```
"""
macro shown(exs...)
    s = gensym()
    esc(quote
        @info $(ShowVars()) $(exs...)
    end)
end

# FIXME: Would it be better and more flexible to just support this via syntax
# in the normal macros? Eg,
#
# @info  _ x y z
# @debug _ x y

