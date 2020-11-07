local M = {}


-- True if s is nil, the empty string, or empty when trimmed.
function M.is_nil_or_whitespace(s)
    return s == nil or M.trim(s) == ''
end


-- Convert nil to empty string, or keep existing value of string.
function M.nil_to_empty(s)
    return s == nil and "" or s
end


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


function M.split_paragraphs(str)
    local paragraphs = {}
    local last_finish = 0
    repeat
        local start, finish = str:find("\n\n", last_finish + 1, true)
        if start == nil then  -- last iteration
            start = #str + 1
            finish = #str + 1
        end

        table.insert(paragraphs, str:sub(last_finish + 1, start - 1))
        last_finish = finish
    until finish > #str
    return paragraphs
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


return M
