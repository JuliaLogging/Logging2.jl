import Base.CoreLogging.LogState

"""
    LoggingStream(logger; level, id)

An `IO` object which collects incoming calls to `write` and writes them to the
Julia logging system via `logger`. Most useful when combined with
`LineBufferedIO`. The standard logging `_id` field will be set to `id`.
"""
struct LoggingStream{Logger <: AbstractLogger, Level} <: IO
    logger::Logger
    logstate::LogState
    id::Symbol
    level::Level
end

function LoggingStream(logger; id, level=Logging.Info)
    LoggingStream(logger, LogState(logger), Symbol(id), level)
end

function Base.unsafe_write(s::LoggingStream, p::Ptr{UInt8}, n::UInt)
    # Remove any trailing newline
    level = Logging.Info
    # Unclear what to set this metadata to, it's not really available.
    id = s.id
    file = :unknown
    line = 0
    group = :io
    _module = Logging
    # These tests capture the essence of the logging early-bailout in Base.CoreLogging.
    #
    # NOTE: These refer to internals of CoreLogging and will need to be kept in
    # sync if things change upstream.
    if #==# level >= Base.CoreLogging._min_enabled_level[] &&
            level >= s.logstate.min_enabled_level &&
            Logging.shouldlog(s.logger, level, _module, group, id)
        m = (n > 0 && unsafe_load(p, n) == UInt8('\n')) ? n-1 : n
        message = unsafe_string(p, m)
        Logging.handle_message(s.logger, level, message, _module, group, id, file, line)
    end
    # Could support some approximation of dynamic scoping with the following,
    # but it's a bit of a hack.
    # @logmsg level message _id=id _file=file _line=line _group=group _module=_module
    return n
end

function Base.write(s::LoggingStream, c::UInt8)
    Base.unsafe_write(s, Ref(c), 1)
end


