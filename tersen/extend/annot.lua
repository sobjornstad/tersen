local util = require 'util'

local M = {}


-- True if /s/ is a one-character string which is [aeiou].
local function is_vowel(s)
    return M.set{"a", "e", "i", "o", "u"}[s] ~= nil
end


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
    return {
        [source] = dest,
        [comparative] = "me" .. dest,
        [superlative] = "my" .. dest,
    }
end


local function pluralize_source (source, args)
    if args == nil then
        if string.sub(source, -1, -1) == "s" then
            return source .. "es"
        elseif string.sub(source, -1, -1) == "y" then
            return source.sub(source, 1, -2) .. "ies"
        else
            return source .. "s"
        end
    else
        return args[1]
    end
end


function M.n (source, dest, args)
    local plural = pluralize_source(source, args)
    return {[source] = dest, [plural] = dest .. "z"}
end


function M.n_acro (source, dest, args)
    local plural = pluralize_source(source, args)
    return {[source] = dest, [plural] = dest .. "s"}
end


function M.v (source, dest, args)
    local third, past, perfect, participle
    if args == nil then
        if is_vowel(source:sub(-1, -1)) then
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

    -- Place more fundamental forms last; if any keys are the same, the ones
    -- that come last win. E.g., it seems less objectionable to have the present of
    -- "run" used for the past participle than vice versa!
    return {
        [third] = dest,
        [past] = "y" .. dest,
        [perfect] = dest .. "d",
        [participle] = "u" .. dest,
        [source] = dest,
    }
end


function M.apos (source, dest, args)
    local straight = string.gsub(source, "'", "’")
    local curly = string.gsub(source, "’", "'")
    return {[straight] = dest, [curly] = dest}
end


function M.numbers (source, dest, args)
    local ones  = {one = 1, two = 2, three = 3, four = 4, five = 5, six = 6,
                   seven = 7, eight = 8, nine = 9}
    local small = {ten = 10, eleven = 11, twelve = 12, thirteen = 13,
                   fourteen = 14, fifteen = 15, sixteen = 16, seventeen = 17,
                   eighteen = 18, nineteen = 19}
    local tens  = {twenty = 20, thirty = 30, forty = 40, fifty = 50,
                   sixty = 60, seventy = 70, eighty = 80, ninety = 90}

    local ninety_nine_blackbirds_sitting_in_a_tree = {}
    for k, v in pairs(ones) do
        ninety_nine_blackbirds_sitting_in_a_tree[k] = tostring(v)
    end
    for k, v in pairs(small) do
        ninety_nine_blackbirds_sitting_in_a_tree[k] = tostring(v)
    end
    for k, v in pairs(tens) do
        ninety_nine_blackbirds_sitting_in_a_tree[k] = tostring(v)
        for kk, vv in pairs(ones) do
            ninety_nine_blackbirds_sitting_in_a_tree[k .. '-' .. kk] = tostring(v + vv)
        end
    end

    return ninety_nine_blackbirds_sitting_in_a_tree
end

return M
