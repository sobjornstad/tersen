M = {}

local function greeken(str)
    local gk_tab = {
        ["ment"] = "μ",
        ["tion"] = "σ",
        ["c?co[mn]"] = "κ",
        ["ship"] = "π",
        ["f?f[iu]ll?"] = "Φ",
        ["ness?"] = "ε",
        ["l?less?"] = "Λ",
        ["ing"] = "γ",
        ["all?"] = "α",
        ["a?l?ly"] = "λ",
        ["[ai]ble"] = "β",
        ["[ai]bility"] = "βt",
    }
    for search, repl in pairs(gk_tab) do
        str = string.gsub(str, search, repl)
    end
    return str
end


function M.no_match (token)
    return greeken(token)
end


return M
