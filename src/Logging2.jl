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
    @eval function Base.$redirect_func(logger::AbstractLogger,
                                       ready::Channel, cancel::Channel)
        prev_stream = $stream_name
        output = LineBufferedIO(LoggingStream(logger, id=$(QuoteNode(stream_name))))
        rd,rw = $redirect_func()
        try
            @sync begin
                Threads.@spawn write(output, rd)
                put!(ready, true)
                take!(cancel)
                flush(rw)
                close(rd)
            end
        finally
            $redirect_func(prev_stream)
            close(rw)
            close(output)
        end
        nothing
    end
end

@doc """
    redirect_stdout(logger::AbstractLogger, ready::Channel, cancel::Channel)

Redirect the stdout stream to `logger`, with each line becoming a log event.
This function will block until `true` is written to the channel `cancel` (ie,
`cancel` acts as a cancellation token). Use `take!(ready)` to ensure that the
redirection is initialized and ready for other tasks.

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
@sync begin
    ready = Channel()
    cancel = Channel()
    Threads.@spawn redirect_stdout(current_logger(), ready, cancel)
    take!(ready)
    # ... do stuff which may involve stdout
    println("Hi")
    run(`ls`)
    put!(cancel, true)
end
```
""" redirect_stdout

@doc """
    redirect_stderr(logger::AbstractLogger, ready::Channel, cancel::Channel)

Redirect the stderr stream to `logger`, with each line becoming a log event.
This function will block until `true` is written to the channel `cancel` (ie,
`cancel` acts as a cancellation token). Use `take!(ready)` to ensure that the
redirection is initialized and ready for other tasks.

See [`redirect_stdout`](@ref) for examples and additional information.
""" redirect_stderr

end
