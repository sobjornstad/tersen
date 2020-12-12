local inspect = require 'inspect'  -- DEBUG
local util = require 'util'
local hooks_mod = require 'hooks'
local lut_mod = require 'lut'


function munge_input(word)
    initial_part, word_part, final_part = string.match(word, "(%W*)([-'’%w]+)(.*)")
    if initial_part == nil or word_part == nil or final_part == nil then
        return nil, word, nil
    else
        return initial_part, word_part, final_part
    end
end

-- Given a replacement and source, decide what casing to use for the replacement.
function normalize_case(new_word, original_word)
    if util.is_nil_or_whitespace(new_word) then
        -- If new_word is emptyish, just return whatever's there.
        return new_word
    elseif util.is_upper(original_word) or util.is_upper(new_word) then
        -- If the original word is uppercase OR the replacement is uppercase
        -- (indicating the replacement is an acronym), use uppercase.
        return string.upper(new_word)
    elseif util.is_title(original_word) then
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

-- Recursively consume tokens from the word list, finding the longest possible
-- match in the lookup table beginning at word_base_index.
function tersen_from(retrieve_point, words, word_base_index, word_at_index)
    if words[word_at_index] == nil then
        -- If we are going beyond the end of our input, this is not a match.
        return nil
    end
    local lowered_word = string.lower(words[word_at_index])

    local initial, munged_word, final = munge_input(lowered_word)
    local this_word = retrieve_point[munged_word]
    if this_word == nil then
        -- No match in this branch.
        return nil
    elseif this_word.continuation == nil then
        -- This is a match, and no longer matches exist.
        return this_word,
            initial,
            final,
            word_at_index - word_base_index + 1
    else
        -- Longer matches may exist; try to consume more tokens.
        item, child_initial, child_final, child_advance = tersen_from(
            this_word.continuation,
            words,
            word_base_index,
            word_at_index + 1)

        if item ~= nil then
            -- Longer match was found. Use child's match.
            return item, initial, child_final, child_advance
        elseif this_word.dest then
            -- No longer match was found. Use our match.
            return this_word, initial, final, word_at_index - word_base_index + 1
        else
            -- No longer match was found, and our match is a continuation-only
            -- entry. Ergo, no match in this branch. :(
            return nil
        end
    end
end

function tersen(lut, text, stats)
    -- Tokenize input into whitespace-separated words.
    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end

    -- Initialize run-global table of unmatched tokens for statistical purposes.
    local tersened = {}
    if _G.unmatched_tokens == nil then
        unmatched_tokens = {}
    end

    -- Work down the list of tokens. At each iteration, greedily consume one
    -- or more matching tokens and advance loop counter by the number of tokens
    -- consumed.
    i = 1
    while i <= #words do
        item, initial, final, advance = tersen_from(lut, words, i, i)
        if item == nil then
            -- No matches found starting at this word.
            -- Insert into dict of nonexistent words.
            tw_munged = words[i]:lower()
            if unmatched_tokens[tw_munged] ~= nil then
                unmatched_tokens[tw_munged] = unmatched_tokens[tw_munged] + 1
            else
                unmatched_tokens[tw_munged] = 1
            end

            local tersened_word
            if hooks_mod.no_match ~= nil then
                tersened_word = hooks_mod.no_match(words[i])
            else
                tersened_word = words[i]
            end
            table.insert(tersened, tersened_word)
            i = i + 1
        else
            -- A match was found. Place the destination value, with surrounding
            -- initial/final punctuation, in the output list.
            if item.dest:sub(-1, -1) == '.' and final:sub(1, 1) == '.' then
                -- If the abbreviation ends with a '.', and there's already a '.' here,
                -- whack one of them.
                final = final:sub(2, -1)
            end
            table.insert(tersened, initial .. normalize_case(item.dest, words[i]) .. final)
            i = i + advance
        end
    end

    result = table.concat(tersened, " ")
    if stats == nil then
        return result
    else
        return result, #text, #result, #result/#text, unmatched_tokens
    end
end

local lut = lut_mod.build("full_tersen.txt")
--local lut = build_lut("tersen_dict.txt")
--print(inspect(lut))

input = io.open("/home/soren/random-thoughts.txt")
orig_tot, new_tot = 0, 0
for i in input:lines() do
    result, orig, new = tersen(lut, i, true)
    print(result)
    orig_tot = orig_tot + orig
    new_tot = new_tot + new
end

print("Stats:", orig_tot, new_tot, new_tot / orig_tot)
print("Unmatched tokens:")
token_mapping = {}
for k, v in pairs(unmatched_tokens) do
    table.insert(token_mapping, {k, v})
end
table.sort(token_mapping, function (left, right) return left[2] > right[2] end)
for index, pair in ipairs(token_mapping) do
    if index > 100 then break end
    print(string.format("%d\t%s", pair[2], pair[1]))
end

--print(tersen(lut, "St. Olaf College"))
--print(tersen(lut, "RED Soren Bjornstad and the red-clothed folk who Random Thoughts like Soren..."))
--print(tersen(lut, '#11336. "After I listen to this song, I like to immediately listen to this song again." --YouTube comment, found by Mama'))
--print(tersen(lut, "Soren and Maud went to the store and it was EASY and Random."))

-- TODO: Unicode normalization?
-- TODO: Convert to title case properly if there is punctuation earlier; ideally each word too
-- TODO: Newline handling
-- TODO: Allow applying multiple annotations
-- TODO: Force case sensitivity?
-- TODO: Improve warnings (print to stderr, give more details)
-- TODO: Add further extensibility points
-- TODO: Run either the missing words OR the tersen, and not both
