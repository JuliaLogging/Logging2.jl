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
    @test_logs (:info, Text("L1"),     Logging, Ignored(), :asdf) #=
            =# (:info, Text("L2"),     Logging, Ignored(), :asdf) #=
            =# (:info, Text("L3\nL4"), Logging, Ignored(), :asdf) #=
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

@testset "redirect_stdout and redirect_stderr" begin
    @test_logs (:info,Text("Hi"))  (:info,Text("Hi2")) #=
        =#     (:info,Text("Hi3")) (:info,Text("Hi4")) #=
        =# redirect_stdout(current_logger()) do
            println("Hi")
            println("Hi2\nHi3")
            print("Hi")
            print("4")
            print("\n")
        end

    # test return value from `redirect_stdout`
    @test (@test_logs (:info,Text("Hi")) redirect_stdout(current_logger()) do
        println("Hi")
        101
    end) == 101

    @test_logs (:info,Text("Hi")) #=
        =# redirect_stderr(current_logger()) do
            println(stderr, "Hi")
        end

    @test_logs (:warn,Text("Hi")) #=
        =# redirect_stderr(current_logger(); level=Logging.Warn) do
            println(stderr, "Hi")
        end
end

@testset "@logshow" begin
    x = 1
    @test_logs (:info, Logging2.Shown(["x"=>1])) @logshow x
    y = "hi"
    @test_logs (:info, Logging2.Shown(["x"=>1, "y"=>"hi"])) @logshow x y
    z = 2
    @test_logs (:info, Logging2.Shown(["x + z"=>x+z])) @logshow x+z
end
