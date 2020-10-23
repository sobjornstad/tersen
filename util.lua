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

function M.split_source(source)
    local elts = {}
    for i in string.gmatch(source, "[^,]*") do
        if i == nil then
            print("WARNING: Invalid source directive " .. source)
        else
            table.insert(elts, M.trim(i))
        end
    end
    return #elts == 0 and {source} or elts
end

return M
