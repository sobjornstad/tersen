local M = {}

function M.trim(str)
    if str == nil then return nil end
    return string.match(str, "^%s*(.-)%s*$")
end

-- Return a list of whitespace-separated tokens. If input is nil, return nil.
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
    local new_t = {}
    for k, v in pairs(t) do
        new_t[k] = v
    end
    return new_t
end

function M.set(lst)
    S = {}
    for _, i in ipairs(lst) do
        S[i] = true
    end
    return S
end

-- True if /s/ is a one-character string which is [aeiou].
function M.is_vowel(s)
    return M.set{"a", "e", "i", "o", "u"}[s] ~= nil
end

-- True if s is nil, the empty string, or empty when trimmed.
function M.is_nil_or_whitespace(s)
    return s == nil or M.trim(s) == ''
end

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
        if not M.is_nil_or_whitespace(alnum_run) and alnum_run:match("^%u%l*$") == nil then
            return false
        end
    end
    return true
end

return M
