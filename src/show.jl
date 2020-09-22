struct Shown
    values
end

function Base.:(==)(a::Shown, b::Shown)
    a.values == b.values
end

function Base.show(io::IO, m::MIME"text/plain", shown::Shown)
    for (i,(name,value)) in enumerate(shown.values)
        print(io, name, " = ")
        show(io, value)
        if i < length(shown.values)
            println(io)
        end
    end
end

"""
    @logshow expression1 [expression2 ...]

Like `@show`, but sends the results to the logging system as an object of type
`Logging2.Shown`.

# Examples

```jldoctest
julia> x = [1,2,3]
       s = "hi"
       @logshow x s

┌ Info:
│ x = [1, 2, 3]
└ s = "hi"
```
"""
macro logshow(exs...)
    key_vals = [:($(string(e))=>$(esc(e))) for e in exs]
    quote
        @info Shown([$(key_vals...)])
    end
end

