local hook = require 'tersen.hook_exec'
local util = require 'tersen.util'

local M = {}


-- A string is uppercase if it consists only of one or more capital letters,
-- numbers, punctuation, and whitespace. Nil and the empty string are not
-- uppercase.
function M.is_upper(str)
    return str ~= nil and str:match("^[%u%d%p%s]+$") ~= nil
end


-- A string is lowercase if it consists only of one or more lowercase letters,
-- numbers, punctuation, and whitespace. Nil and the empty string are not
-- lowercase.
function M.is_lower(str)
    return str ~= nil and str:match("^[%l%d%p%s]+$") ~= nil
end


-- A string is title-case if it consists of runs of alphanumeric characters/apostrophes
-- where the first character is uppercase and the rest are not; the runs may be
-- separated by any other characters. Nil and the empty string are not title-case.
function M.is_title(str)
    if str == nil or #str == 0 then
        return false
    end

    for alnum_run in str:gmatch("[%w'’]*") do
        if not util.is_nil_or_whitespace(alnum_run)
          and alnum_run:match("^%u[%l%d'’]*$") == nil then
            return false
        end
    end
    return true
end


-- To convert a string to title case, uppercase the first letter in every word,
-- a word consisting of a consecutive run of letters, hyphens, underscores,
-- or apostrophes.
function M.to_title(str)
    local in_word = false
    local new_chars = {}

    for i = 1, #str do
        local c = str:sub(i, i)
        if c:match("[-_'’%a]") then
            if not in_word then
                c = c:upper()
            end
            in_word = true
        else
            in_word = false
        end
        table.insert(new_chars, c)
    end

    return table.concat(new_chars, "")
end


-- Standard behavior of normalize_case. May be overridden by a hook.
local function default_normalize_case(new_word, original_word)
    if util.is_nil_or_whitespace(new_word) then
        -- If new_word is emptyish, just return whatever's there.
        return new_word

    elseif M.is_upper(original_word) or M.is_upper(new_word) then
        -- If the original word is all uppercase OR the replacement is all uppercase
        -- (suggesting the replacement is an acronym), use uppercase.
        return string.upper(new_word)

    elseif M.is_title(original_word) then
        -- Otherwise, if the original word is title case, presumably because it
        -- was at the start of a sentence or part of a name, use title case.
        return M.to_title(new_word)

    else
        -- In all other situations, use the case of the replacement.
        return new_word
    end
end


-- Given a replacement and source, decide what casing to use for the replacement.
function M.normalize(new_word, original_word)
    if hook.defined("normalize_case") then
        local hooked_case = hook.invoke("normalize_case", new_word, original_word)
        if hooked_case ~= nil then
            return hooked_case
        end
    end

    return default_normalize_case(new_word, original_word)
end

return M