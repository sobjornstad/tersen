local inspect = require 'inspect'  -- DEBUG
local util = require 'util'
local hooks = require 'hooks'
local lut_mod = require 'lut'


-- Split a token into its inner portion and its initial/final portions.
local function delineate(word)
    local initial_part, word_part, final_part = string.match(word, "(%W*)([-'’%w]+)(.*)")
    if initial_part == nil or word_part == nil or final_part == nil then
        return nil, word, nil
    else
        return initial_part, word_part, final_part
    end
end


-- Standard behavior of normalize_case. May be overridden by a hook.
local function default_normalize_case(new_word, original_word)
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


-- Given a replacement and source, decide what casing to use for the replacement.
local function normalize_case(new_word, original_word)
    if hooks.normalize_case ~= nil then
        local hooked_case = hooks.normalize_case(new_word, original_word)
        if hooked_case ~= nil then
            return hooked_case
        end
    end

    return default_normalize_case(new_word, original_word)
end


-- Recursively consume tokens from the word list, finding the longest possible
-- match in the lookup table beginning at word_base_index.
local function tersen_from(retrieve_point, words, word_base_index, word_at_index)
    if words[word_at_index] == nil then
        -- If we are going beyond the end of our input, this is not a match.
        return nil
    end

    local lowered_word = string.lower(words[word_at_index])
    local initial, inner_token, final = delineate(lowered_word)
    local this_word = retrieve_point[inner_token]
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
        local item, child_initial, child_final, child_advance = tersen_from(
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


-- Iterate over a series of tokens from /text/ tersened with reference to /lut/.
-- On each iteration, yield the source word, the tersened item,
-- and the initial/final token perimeter.
local function tersened_words(lut, text)
    -- Tokenize input into whitespace-separated words.
    local words = {}
    for word in string.gmatch(text, "%S+") do
        table.insert(words, word)
    end

    local i = 1
    return function()
        while i <= #words do
            local item, initial, final, advance = tersen_from(lut, words, i, i)
            local source_word = words[i]
            if advance == nil then
                i = i + 1
            else
                i = i + advance
            end
            return source_word, item, initial, final
        end
    end
end


local function print_unmatched_tokens(unmatched_frequency_table)
    local token_mapping = {}
    for k, v in pairs(unmatched_frequency_table) do
        table.insert(token_mapping, {k, v})
    end
    table.sort(token_mapping, function (left, right) return left[2] > right[2] end)

    print("Unmatched tokens:")
    for index, pair in ipairs(token_mapping) do
        if index > 100 then break end
        print(string.format("%d\t%s", pair[2], pair[1]))
    end
end


-- Return a table from words to frequency, containing all words in /text/ that
-- didn't match an entry in the lookup table /lut/.
local function unmatched_in_corpus(lut, text)
    local unmatched = {}
    for source_word, item in tersened_words(lut, text) do
        if item == nil then
            local _, inner_tok, _ = delineate(source_word)
            local report_as = inner_tok:lower()
            if unmatched[report_as] ~= nil then
                unmatched[report_as] = unmatched[report_as] + 1
            else
                unmatched[report_as] = 1
            end
        end
    end
    return unmatched
end


local function tersen(lut, text)
    local tersened = {}
    for source_word, item, initial, final in tersened_words(lut, text) do
        if item == nil then
            local tersened_word
            if hooks.no_match ~= nil then
                tersened_word = hooks.no_match(source_word)
            else
                tersened_word = source_word
            end
            table.insert(tersened, tersened_word)
        else
            if item.dest:sub(-1, -1) == '.' and final:sub(1, 1) == '.' then
                -- If the abbreviation ends with a '.', and there's already a '.' here,
                -- whack one of them.
                final = final:sub(2, -1)
            end
            table.insert(tersened,
                         initial .. normalize_case(item.dest, source_word) .. final)
        end
    end

    local result = table.concat(tersened, " ")
    return result, #text, #result, #result/#text
end


local lut = lut_mod.build_from_dict_file("full_tersen.txt")
lut_mod.trace(lut)
--local myfile = io.open("/home/soren/random-thoughts.txt")
--local unmatched = unmatched_in_corpus(lut, myfile:read("*a"))
--print_unmatched_tokens(unmatched)
--os.exit(1)
--local lut = build_lut("tersen_dict.txt")
--print(inspect(lut))

local input = io.open("/home/soren/random-thoughts.txt")
local orig_tot, new_tot = 0, 0
for i in input:lines() do
    local result, orig, new = tersen(lut, i)
    print(result)
    orig_tot = orig_tot + orig
    new_tot = new_tot + new
end

print("Stats:", orig_tot, new_tot, new_tot / orig_tot)

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

-- TODO: Annotations incorrectly add the non-annotated part without passing through
-- TODO: insert_mapping may not work correctly when the destination is set differently for different annotation returns...it appears to use the raw item for that.
