module Logging2

using Logging

include("LineBufferedIO.jl")
include("LoggingStream.jl")

#-------------------------------------------------------------------------------
# Utilities

"""
    redirect_stdout(logger::AbstractLogger, cancel)

Redirect the stdout stream to `logger`, with each line becoming a log event.
This function will block until any value is written to the channel `cancel`
(ie, `cancel` acts as a cancellation token).

!!! note
    In contrast to the dynamic scope of the usual logging system frontend (`@info`,
    etc), `stdout` is a global object so it's not entirely clear that we can
    collect the logger from the current dynamic scope where `Base.stdout` is
    looked up, and efficiently use it.

    In particular, some particular uses of stdout require it to have an
    operating system primitive like a `Pipe` backing the object. However not
    all uses require this, and it may be possible to improve the situation in
    the future.

# Example

Here's how you use `redirect_stdout` in structured concurrency style:

```
@sync begin
    cancel = Channel()
    Threads.@spawn redirect_stdout(current_logger(), cancel)
    yield()
    println("Hi")
    # ... do stuff which may involve stdout
    put!(cancel, true)
end
```
"""
function Base.redirect_stdout(logger::AbstractLogger, cancel)
    prev_stdout = stdout
    output = LineBufferedIO(LoggingStream(logger, id=:stdout))
    rd,rw = Base.redirect_stdout()
    try
        @sync begin
            Threads.@spawn write(output, rd)
            take!(cancel)
            close(rd)
        end
    finally
        Base.redirect_stdout(prev_stdout)
        close(rw)
        close(output)
    end
    nothing
end

end
