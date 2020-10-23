local M = {}

function M.trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

function M.split_whitespace(str)
    if str == nil then
        return nil
    end

    local T = {}
    for i in string.gmatch(str, "%S+") do
        table.insert(T, i)
    end
    return T
end

function M.shallow_copy(t)
    new_t = {}
    for k, v in pairs(t) do
        new_t[k] = v
    end
    return new_t
end

return M
