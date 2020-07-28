using Logging2
using Logging
using Test

@testset "redirect_stdout(::AbstractLogger)" begin
    @test_logs (:info,"Hi") (:info,"Hi2") (:info,"Hi3") (:info,"Hi4") @sync begin
        cancel = Channel()
        Threads.@spawn redirect_stdout(current_logger(), cancel)
        yield()
        println("Hi")
        println("Hi2\nHi3")
        print("Hi")
        print("4")
        print("\n")
        put!(cancel, true) # kill the task listening on the pipe
    end
end

# TODO Unit test LineBuffer
#@testset "LineBuffer" begin
#end
