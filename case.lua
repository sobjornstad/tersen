local hooks = require 'hooks'
local util = require 'util'

local M = {}


-- TODO: Should these three functions handle control characters?
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


-- A string is title-case if it consists of numbers, punctuation, and
-- whitespace separated by runs of alphanumeric characters where the first
-- alphanumeric character is uppercase and the rest are lowercase. Nil
-- and the empty string are not title-case.
function M.is_title(str)
    if str == nil or #str == 0 then
        return false
    end

    for alnum_run in str:gmatch("[^%d%p%s]*") do
        if not util.is_nil_or_whitespace(alnum_run) and alnum_run:match("^%u%l*$") == nil then
            return false
        end
    end
    return true
end


-- Standard behavior of normalize_case. May be overridden by a hook.
local function default_normalize_case(new_word, original_word)
    if util.is_nil_or_whitespace(new_word) then
        -- If new_word is emptyish, just return whatever's there.
        return new_word

    elseif M.is_upper(original_word) or M.is_upper(new_word) then
        -- If the original word is uppercase OR the replacement is uppercase
        -- (indicating the replacement is an acronym), use uppercase.
        return string.upper(new_word)

    elseif M.is_title(original_word) then
        -- Otherwise, if the original word is title case, presumably because it
        -- was at the start of a sentence or part of a name, use title case.
        local initial, first_alnum, final = new_word:match("^(.-)(%w)(.*)$")
        if first_alnum == nil then
            -- Special case: no alphanumeric characters at all in replacement.
            -- Just return the replacement.
            return new_word
        else
            return initial .. first_alnum:upper() .. final
        end

    else
        -- In all other situations, use the case of the replacement.
        return new_word
    end
end


-- Given a replacement and source, decide what casing to use for the replacement.
function M.normalize(new_word, original_word)
    if hooks.normalize_case ~= nil then
        local hooked_case = hooks.normalize_case(new_word, original_word)
        if hooked_case ~= nil then
            return hooked_case
        end
    end

    return default_normalize_case(new_word, original_word)
end


return M