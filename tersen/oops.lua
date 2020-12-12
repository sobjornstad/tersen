local M = {}
M.warnings = {}


function M.warn(msg, ...)
    local formatted = string.format(msg, ...)
    table.insert(M.warnings, formatted)
    io.stderr:write("WARNING: " .. formatted .. "\n")
end


function M.warn_source(line, msg, ...)
    return M.warn("line %d: " .. msg, line, ...)
end


function M.die(err_code, msg, ...)
    if err_code == nil then
        err_code = 1
    end
    local formatted = string.format(msg, ...)
    io.stderr:write("ERROR: " .. formatted .. "\n")
    os.exit(err_code)
end


function M.num_warnings()
    local num = 0
    for _, __ in pairs(M.warnings) do
        num = num + 1
    end
    return num
end


return M