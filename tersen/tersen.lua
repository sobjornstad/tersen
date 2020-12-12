local inspect = require 'inspect'

local case = require 'tersen.case'
local hook = require 'tersen.hook_exec'
local util = require 'tersen.util'

local M = {}

-- Split a token into its inner portion and its initial/final portions.
local function delineate(word)
    local initial_part, word_part, final_part = string.match(word, "(%W*)([-'’%w]+)(.*)")
    if initial_part == nil or word_part == nil or final_part == nil then
        return nil, word, nil
    else
        return initial_part, word_part, final_part
    end
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
-- and the whitespace/initial/final token perimeter.
local function tersened_words(lut, text)
    local whitespaces = {}
    local words = {}
    for whitespace, word in string.gmatch(text, "(%s*)(%S+)") do
        table.insert(words, word)
        table.insert(whitespaces, whitespace)
    end

    local i = 1
    return function()
        while i <= #words do
            local item, initial, final, advance = tersen_from(lut, words, i, i)
            local source_word = words[i]
            local whitespace = whitespaces[i]
            if advance == nil then
                i = i + 1
            else
                i = i + advance
            end
            return source_word, item, whitespace, initial, final
        end
    end
end


-- Print unmatched tokens compiled by unmatched_in_corpus() to stdout.
function M.print_unmatched_tokens(unmatched_frequency_table)
    local token_mapping = {}
    for k, v in pairs(unmatched_frequency_table) do
        table.insert(token_mapping, {k, v})
    end
    table.sort(token_mapping, function (left, right) return left[2] > right[2] end)

    for index, pair in ipairs(token_mapping) do
        print(string.format("%d\t%s", pair[2], pair[1]))
    end
end


-- Return a table from words to frequency, containing all words in /text/ that
-- didn't match an entry in the lookup table /lut/.
function M.unmatched_in_corpus(lut, text)
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


-- Return a tersened version of the string /text/, tersening with reference to the
-- lookup table /lut/.
function M.tersen(lut, text)
    local tersened = {}
    for source_word, item, whitespace, initial, final in tersened_words(lut, text) do
        if item == nil then
            local tersened_word = hook.try_invoke("no_match", source_word)
                :or_return(source_word)
            table.insert(tersened, util.nil_to_empty(whitespace) .. tersened_word)
        else
            if item.dest:sub(-1, -1) == '.' and final:sub(1, 1) == '.' then
                -- If the abbreviation ends with a '.', and there's already a '.' here,
                -- whack one of them.
                final = final:sub(2, -1)
            end
            local insert = whitespace
                           .. initial
                           .. case.normalize(item.dest, source_word)
                           .. final
            table.insert(tersened, insert)
        end
    end

    local result = table.concat(tersened, "")
    return result, #text, #result, #result/#text
end

return M