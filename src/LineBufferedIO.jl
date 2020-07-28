"""
    LineBufferedIO(dest::IO)

A thread safe line buffered IO wrapper which buffers writes until a full line
(delimited by '\\n') is received. Full lines are written to the downstream
`dest` `IO`.

To ensure that the tail of the stream is written (even without a trailing
'\\n'), be sure to call `close()`.
"""
struct LineBufferedIO{DestIO<:IO} <: IO
    buf::IOBuffer
    buf_lock::ReentrantLock
    dest::DestIO
end

function LineBufferedIO(dest::IO)
    LineBufferedIO(IOBuffer(), ReentrantLock(), dest)
end

function Base.unsafe_write(io::LineBufferedIO, p::Ptr{UInt8}, n::UInt)
    first_newline = nothing
    last_newline = nothing
    for i = 1:n
        if unsafe_load(p, i) == UInt8('\n')
            first_newline = i
            break
        end
    end
    if !isnothing(first_newline)
        for i = n:-1:1
            if unsafe_load(p, i) == UInt8('\n')
                last_newline = i
                break
            end
        end
    end
    firstline = nothing
    unbuf_start = nothing
    unbuf_end = 0
    lock(io.buf_lock) do
        # Invariant: `buf` buffers the prefix of the current line
        buf = io.buf
        if isnothing(first_newline)
            # No newline: just buffer the whole thing
            unsafe_write(buf, p, n)
            unbuf_start = 1
            unbuf_end = 0
        else
            if position(buf) != 0
                unsafe_write(buf, p, first_newline)
                # At this point we have one full line in the buffer
                firstline = take!(buf)
                unbuf_start = first_newline+1
            else
                unbuf_start = 1
            end
            if last_newline != n
                # Also record any trailing chars into the buffer
                unsafe_write(buf, p+last_newline, n-last_newline)
            end
            unbuf_end = last_newline
        end
    end
    if !isnothing(firstline)
        write(io.dest, firstline)
    end
    linestart = unbuf_start
    for i = unbuf_start:unbuf_end
        if unsafe_load(p, i) == UInt8('\n')
            unsafe_write(io.dest, p + linestart-1, i - linestart + 1)
            linestart = i+1
        end
    end
    return n
end

function Base.write(io::LineBufferedIO, c::UInt8)
    Base.unsafe_write(io, Ref(c), 1)
end

function Base.close(io::LineBufferedIO)
    local remaining_line
    lock(io.buf_lock) do
        remaining_line = take!(io.buf)
        close(io.buf)
    end
    if !isempty(remaining_line)
        write(io.dest, remaining_line)
    end
end

Base.isopen(io::LineBufferedIO) = lock(()->isopen(io.buf), io.buf_lock)


