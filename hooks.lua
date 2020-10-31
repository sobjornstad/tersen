local M = {}

--[[
no_match()

Description:
    no_match() allows you to transform tokens that do not match any mapping in the
    tersen dictionary. For instance, you might try abbreviating substrings.

Parameters:
  @outer_token  The outer token that didn't match.

Return:
    The token you want to replace this one in the output stream.
    (If you don't want to change anything, just return outer_token.)

Notes:
    This is an extremely "hot" function since it runs for every word in the input
    that can't be abbreviated from your dictionary. Make your implementation run as
    fast as possible.
--]
function M.no_match(outer_token)
    return outer_token
end
--]]


--[[
normalize_case()

Description:
    normalize_case() is called to determine the case of a replacement.
    If tersen's default rules are causing things to be uppercase that shouldn't be,
    or you want all output to be in tOGGLE cASE, you can do that here.

    Note that normalize_case() is NOT called if no replacement is found; then the word
    keeps its original case. If you need to re-case words that were not tersened, you
    can do that in no_match().

Parameters:
  @new_word   The replacement (tersened) inner token.
  @orig_word  The original inner token.

Return:
    The inner token you want to use in the output stream,
    or 'nil' to delegate the case replacement to tersen's default algorithm
    (found in case.lua).

Notes:
    Like no_match(), this is an extremely "hot" function; this one runs for every word
    in the input that *can* be abbreviated from your dictionary.
    Make your implementation run as fast as possible.
--]
function M.normalize_case(new_word, orig_word)
    return nil
end
--]]


--[[
trace()

Description:
    After tersen finishes building a lookup table, it checks to see if any
    trace flags are on in the dictionary (lines beginning with ?) and prints
    those. trace() is called immediately after handling the tracing flags. If
    you want to inspect a complicated problem using Lua code rather than
    flagging a bunch of lines and poring over the output, you can do so in
    this hook.

Parameters:
  @lut   The complete tersen lookup table.

Return:
    The return value of this hook is ignored.

Notes:
    Do not alter the lookup table; this may result in undefined behavior.
    If you actually want to alter the lookup table, instead use post_build_lut().
--]
function M.trace(lut)

end
--]]


--[[
post_build_lut()

Description:
    After tersen finishes building a lookup table based on the tersen dictionary,
    it calls post_build_lut() so that you can make arbitrary modifications
    to the table.

    If you want to programmatically add many entries to the table, you can also
    accomplish this with annotations; which to use is a matter of taste.

Parameters:
  @lut   The complete tersen lookup table.

Return:
    The new tersen lookup table you want to use. It is safe to modify the table
    in place and 'return lut' if that is most convenient.
--]
function M.post_build_lut(lut)

end
--]]


--[[
mapping_verbosens_text()

Description:
    If a mapping is found that is longer than its corresponding source,
    mapping_verbosens_text() decides what to do.

    If this hook is not defined, tersen will print a warning and use the
    mapping unchanged.

Parameters:
  @source  The source of the mapping.
  @dest    The replacement of the mapping (longer than source)
  @item    The lookup-table value for this destination,
           containing properties like the original source directive and line number.

Return:
    A source, destination pair for the mapping you want to use,
    or nil if you want to skip including this item in the lookup table entirely.
--]
function M.mapping_verbosens_text(source, dest)
    return source, dest
end
--]]



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


function M.no_match(token)
    return greeken(token)
end


return M
