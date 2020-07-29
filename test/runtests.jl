using Logging2
using Logging
using Test
using Test: Ignored

struct IOWriteRecord <: IO
    writes
end

IOWriteRecord() = IOWriteRecord(Vector{String}())

function Base.unsafe_write(io::IOWriteRecord, p::Ptr{UInt8}, n::UInt)
    push!(io.writes, unsafe_string(p, n))
end

@testset "LineBufferedIO" begin
    function buffer_lines(strs...)
        w = IOWriteRecord()
        lbuf = Logging2.LineBufferedIO(w)
        for s in strs
            write(lbuf, s)
        end
        w.writes
    end

    @test buffer_lines("a", "\n") == ["a\n"]
    @test buffer_lines('a', '\n') == ["a\n"]
    @test buffer_lines("a", "b", "\n") == ["ab\n"]
    @test buffer_lines("a", "b", "\n", "c") == ["ab\n"]
    @test buffer_lines("a", "b", "\n", "c", "d\n") == ["ab\n", "cd\n"]
    @test buffer_lines("\n", "\n") == ["\n", "\n"]

    @test buffer_lines("ab\nc", "d") == ["ab\n"]
    @test buffer_lines("ab\nc", "d", "\n") == ["ab\n", "cd\n"]
    @test buffer_lines("ab\ncd\ne", "f", "\n") == ["ab\n", "cd\n", "ef\n"]
    @test buffer_lines("a", "b\ncd\ne", "f", "\n") == ["ab\n", "cd\n", "ef\n"]
    @test buffer_lines("a", "b\ncd\n", "ef", "\n") == ["ab\n", "cd\n", "ef\n"]
end

@testset "LoggingStream" begin
    @test_logs (:info, "L1",     Logging, Ignored(), :asdf) #=
            =# (:info, "L2",     Logging, Ignored(), :asdf) #=
            =# (:info, "L3\nL4", Logging, Ignored(), :asdf) #=
    =# begin
        ls = Logging2.LoggingStream(current_logger(), id=:asdf)
        write(ls, "L1")
        write(ls, "L2\n")
        write(ls, "L3\nL4") # No buffering!
    end

    # Check that log level early-out testing works
    @test_logs min_level=Logging.Warn begin
        ls = Logging2.LoggingStream(current_logger(), id=:asdf)
        write(ls, "L1")
    end
end

@testset "redirect_stdout(::AbstractLogger)" begin
    @test_logs (:info,"Hi") (:info,"Hi2") (:info,"Hi3") (:info,"Hi4") @sync begin
        ready = Channel()
        cancel = Channel()
        Threads.@spawn redirect_stdout(current_logger(), ready, cancel)
        # TODO: This is very manual and ugly.
        take!(ready)
        println("Hi")
        println("Hi2\nHi3")
        print("Hi")
        print("4")
        print("\n")
        put!(cancel, true) # kill the task listening on the pipe
    end
end

