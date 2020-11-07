local M = {}
M.warnings = {}


function M.warn(msg, ...)
    local formatted = string.format(msg, ...)
    table.insert(M.warnings, formatted)
    io.stderr:write("WARNING: " .. formatted .. "\n")
end


function M.num_warnings()
    local num = 0
    for _, __ in pairs(M.warnings) do
        num = num + 1
    end
    return num
end


return M