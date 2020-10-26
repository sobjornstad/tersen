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
