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
(which acts as a cancellation token).

# Example

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
