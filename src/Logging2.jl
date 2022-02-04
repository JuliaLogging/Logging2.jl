module Logging2

using Logging

include("LineBufferedIO.jl")
include("LoggingStream.jl")

#-------------------------------------------------------------------------------
# Utilities


function _redirect_to_logger(f::Function, logger::AbstractLogger,
                             level_for_logs, redirect_func, prev_stream, stream_name)
    result = nothing

    output = LineBufferedIO(LoggingStream(logger; id=stream_name, level=level_for_logs))
    rd,rw = redirect_func()
    try
        @sync begin
            try
                Threads.@spawn write(output, rd) # loops while !eof(rd)
                result = f()
            finally
                # To close the read side of the pipe, we must close *all*
                # writers. This includes `rw`, but *also* the dup'd fd
                # created behind the scenes by redirect_func(). (To close
                # that, must call redirect_func() here with the prev stream.)
                close(rw)
                redirect_func(prev_stream)
            end
        end
    finally
        close(rd)
        close(output)
    end
    return result
end

# Incompatibility due to
# https://github.com/JuliaLang/julia/pull/39132
@static if VERSION < v"1.7"

for (redirect_func, stream_name) in [
        (:redirect_stdout, :stdout),
        (:redirect_stderr, :stderr)
    ]
    @eval function Base.$redirect_func(f::Function, logger::AbstractLogger; level=Logging.Info)
        _redirect_to_logger(f, logger, level, $redirect_func,
                            $stream_name, $(QuoteNode(stream_name)))
    end
end

else

function (redirect_func::Base.RedirectStdStream)(f::Function, logger::AbstractLogger; level=Logging.Info)
    # See https://github.com/JuliaLang/julia/blob/294b0dfcd308b3c3f829b2040ca1e3275595e058/base/stream.jl#L1417
    prev_stream, stream_name =
        redirect_func.unix_fd == 0 ? (stdin, :stdin) :
        redirect_func.unix_fd == 1 ? (stdout, :stdout) :
        redirect_func.unix_fd == 2 ? (stderr, :stderr) :
        throw(ArgumentError("Not implemented to get old handle of fd except for stdio"))

    _redirect_to_logger(f, logger, level, redirect_func, prev_stream, stream_name)
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
