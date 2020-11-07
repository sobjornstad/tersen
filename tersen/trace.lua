local inspect = require 'inspect'  -- DEBUG

local hook = require 'tersen.hook_exec'
local oops = require 'tersen.oops'

local M = {}

-- An item needs to be printed in a trace if it has a ? flag or if any child does.
local function needs_print(item)
    if item.flags ~= nil and item.flags:match("%?") then
        return true
    end

    if item.continuation ~= nil then
        for _, child_item in pairs(item.continuation) do
            if needs_print(child_item) then
                return true
            end
        end
    end

    return false
end


-- Print all items in the provided lookup table that have a trace flag on.
function M.trace(lut)
    local prints = {}
    for k, v in pairs(lut) do
        if needs_print(v) then
            table.insert(prints, k .. ' => ' .. inspect(v))
        end
    end

    if #prints > 0 then
        local ess = (#prints == 1) and '' or 's'
        oops.warn("At least one trace flag was found in the dictionary.")
        io.stderr:write(string.format(
            "Traced replacements for %d root node%s and children:\n",
            #prints, ess))
        for _, v in ipairs(prints) do
            io.stderr:write(v .. "\n")
        end
    end

    hook.invoke("trace", lut)
end

return M
