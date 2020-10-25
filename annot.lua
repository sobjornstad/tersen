local util = require 'util'

M = {}

function M.adj (source, dest, args)
    local comparative, superlative
    if args == nil then
        if string.sub(source, -1, -1) == "e" then
            comparative = source .. "r"
            superlative = source .. "st"
        else
            comparative = source .. "er"
            superlative = source .. "est"
        end
    else
        comparative, superlative = table.unpack(args)
    end
    return {[comparative] = "me" .. dest, [superlative] = "my" .. dest}
end

function M.n (source, dest, args)
    local plural
    if args == nil then
        if string.sub(source, -1, -1) == "s" then
            plural = source .. "es"
        elseif string.sub(source, -1, -1) == "y" then
            plural = source.sub(source, 1, -2) .. "ies"
        else
            plural = source .. "s"
        end
    else
        plural = args[1]
    end
    return {[plural] = dest .. "z"}
end

function M.v (source, dest, args)
    local third, past, perfect, participle
    if args == nil then
        if util.is_vowel(source:sub(-1, -1)) then
            past = source .. "d"
            participle = source:sub(1, -2) .. "ing"
        else
            past = source .. "ed"
            participle = source .. "ing"
        end
        perfect = past
        third = source .. "s"
    else
        third, past, perfect, participle = table.unpack(args)
    end
    -- If any are the same, they will be silently collapsed.
    return {[third] = dest,
            [past] = "y" .. dest,
            [perfect] = dest .. "d",
            [participle] = "u" .. dest}
end

return M
