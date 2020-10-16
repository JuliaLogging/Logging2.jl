module Logging2

using Logging

include("LineBufferedIO.jl")
include("LoggingStream.jl")

#-------------------------------------------------------------------------------
# Utilities

for (redirect_func, stream_name) in [
        (:redirect_stdout, :stdout),
        (:redirect_stderr, :stderr)
    ]
    @eval function Base.$redirect_func(f::Function, logger::AbstractLogger; level=Logging.Info)
        result = nothing
        prev_stream = $stream_name
        output = LineBufferedIO(LoggingStream(logger, id=$(QuoteNode(stream_name)); level=level))
        rd,rw = $redirect_func()
        try
            @sync begin
                try
                    Threads.@spawn write(output, rd) # loops until !eof(rd)
                    result = f()
                finally
                    # To close the read side of the pipe, we must close *all*
                    # writers. This includes `rw`, but *also* the dup'd fd
                    # created behind the scenes by redirect_func(). (To close
                    # that, must call redirect_func() here with the prev stream.)
                    close(rw)
                    $redirect_func(prev_stream)
                end
            end
        finally
            close(rd)
            close(output)
        end
        return result
    end
end

@doc """
    redirect_stdout(f::Function, logger::AbstractLogger)

Redirect the global stdout stream to `logger`, with each line becoming a log
event during the execution of the function `f`.

!!! note
    In contrast to the dynamic scope of the usual logging system frontend (`@info`,
    etc), `stdout` is a global object so it's not entirely clear that we can
    collect the logger from the current dynamic scope where `Base.stdout` is
    looked up, and efficiently use it.

    In particular, some particular uses of stdout require it to have an
    operating system primitive like a `Pipe` backing the object. However not
    all uses require this, and it may be possible to improve the situation in
    the future.

# Examples

Here's how you use `redirect_stdout` in structured concurrency style:

```
redirect_stdout(current_logger()) do
    println("Hi")
    run(`ls`)
end
```
""" redirect_stdout

@doc """
    redirect_stderr(f::Function, logger::AbstractLogger)

Redirect the global stderr stream to `logger`, with each line becoming a log
event during the execution of the function `f`.

See [`redirect_stdout`](@ref) for examples and additional information.
""" redirect_stderr

end
