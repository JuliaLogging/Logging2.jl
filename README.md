# Logging2

[![Build Status](https://github.com/c42f/Logging2.jl/workflows/CI/badge.svg)](https://github.com/c42f/Logging2.jl/actions)

**Logging2** is a library which extends the standard Julia
[Logging library](https://docs.julialang.org/en/v1/stdlib/Logging) with
additional functionality. The intent of this library is to consolidate some
of the more useful "core" logging functionality from the wider Julia ecosystem,
and serve as a staging area to improve the logging standard library itself.

## How-To

### Redirect stdout or stderr to the logging system

Use `redirect_stdout` or `redirect_stderr` to redirect all strings written to
`stdout` or `stderr` to any `AbstractLogger` during the execution of a given
`do` block:

```julia
logger = current_logger() # or construct one explicitly
redirect_stdout(logger) do
    println("Hi")
    run(`ls`)
end
```

Note that `stdout` and `stder` are **global** streams, so this logging choice
is made globally for the whole program. Therefore, you should probably only do
this at the top level of your application (certainly never in any library
code which you expect to run concurrently).

