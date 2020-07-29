# Logging2

[![Build Status](https://github.com/c42f/Logging2.jl/workflows/CI/badge.svg)](https://github.com/c42f/Logging2.jl/actions)

**Logging2** is a library which extends the standard Julia
[Logging library](https://docs.julialang.org/en/v1/stdlib/Logging) with
additional functionality. The intent of this library is to consolidate some
of the more useful "core" logging functionality from the wider Julia ecosystem,
and serve as a staging area to improve the logging standard library itself.

## How-To

### Redirect stdout to the logging system

Use `Base.redirect_stdout` to redirect all strings written to `Base.stdout`
to any AbstractLogger as in the following example (written in
structured-concurrency style):

```julia
@sync begin
    ready = Channel()
    cancel = Channel()
    Threads.@spawn redirect_stdout(current_logger(), ready, cancel)
    take!(ready)
    println("Hi")
    run(`ls`)
    # ... do other stuff which may involve stdout
    put!(cancel, true)
end
```

## The Wider Julia Logging Ecosystem

As of mid-2020, here is a list of libraries from the Julia ecosystem which
relate to the standard logging infrastructure.

First off, `Base` exports the four logging frontend macros `@debug`, `@info`,
`@warn`, `@error` and the stdlib
[`Logging`](https://docs.julialang.org/en/v1/stdlib/Logging) library provides a
default logger backend `ConsoleLogger` for some basic filtering and pretty
printing of log records in the terminal. It combines convenient but
non-composable features into a single logger type.

### Frontend

* [`ProgressLogging.jl`](https://github.com/JunoLab/ProgressLogging.jl)
  provides some convenient frontend macros including `@progress` which makes it
  easy to emit log records tracking the progress of looping constructs.

### Log Event routing and transformation

* [`LoggingExtras.jl`](https://github.com/oxinabox/LoggingExtras.jl) provides
  generic log transformation, filtering and routing functionality. You can use
  this to mutate messages as they go through the chain, duplicate a stream of
  log records into multiple streams, discard messages based on a predicate, etc.

### Sinks

* [`TerminalLoggers.jl`](https://github.com/c42f/TerminalLoggers.jl) is a
  library for advanced terminal-based pretty printing of log records, including
  fancy progress bars and markdown formatting.
* [`TensorBoardLogger.jl`](https://github.com/PhilipVinc/TensorBoardLogger.jl)
  can log structured numeric data to
  [TensorBoard](https://www.tensorflow.org/tensorboard) as a backend.
* [`LogRoller.jl`](https://github.com/tanmaykm/LogRoller.jl) has a backend for
  rotating log files once they hit a size limit.
* [`Syslogging.jl`](https://github.com/tanmaykm/SyslogLogging.jl) provides a
* backend to direct logs to syslog.
* [`LoggingExtras.jl`](https://github.com/oxinabox/LoggingExtras.jl) provides a
  simple `FileLogger` sink.

### Configuration

* [`LogCompose.jl`](https://github.com/tanmaykm/LogCompose.jl) provides
  declarative logger configuration and an associated `.toml` file format.

