local log = log

---@param text string
local function log_info(text)
    log.info(text)
end

---@param text string
local function log_warn(text)
    return log.warn(text)
end

--- Requires DebugView or a debugger to see this. Can also be viewed in the debug console spawned with &quot;Spawn Debug Console&quot; under ScriptRunner.
---@param text string
local function log_debug(text)
    log.debug(text)
end

---@param text string
local function log_error(text)
    return log.error(text)
end

return {
    info = log_info,
    warn = log_warn,
    debug = log_debug,
    error = log_error,
}
