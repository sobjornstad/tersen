local inspect = require 'inspect'  -- DEBUG
local util = require 'util'
local annot_mod = require 'annot'
local hooks_mod = require 'hooks'


function explode_annot(source, dest, annot)
    local annot_name, annot_parmstart = annot:match("^@([%w_]+)([%[%{]?)")
    if annot_name == nil then
        -- invalid annotation, TODO raise warning
        return nil
    end

    local annot_parms
    if util.is_nil_or_whitespace(annot_parmstart) then
        annot_parms = nil
    elseif annot_parmstart == '[' then
        annot_parms = util.split_whitespace(annot:match("^@[%w_]+%[(.*)%]"))
    elseif annot_parmstart == '{' then
        local parm_string = annot:match("^@[%w_]+%{(.*)}"):gsub('}{', '\0')
        annot_parms = {}
        for i in string.gmatch(parm_string, "[^\0]+") do
            table.insert(annot_parms, i)
        end
    else
        error("Oops, this should never happen: annot_parmstart was '"
              .. annot_parmstart .. "'")
    end

    annot_fn = annot_mod[annot_name:lower()]
    if annot_fn == nil then
        print(string.format(
            "WARNING: Attempt to call a nonexistent annotation '%s'. This line will be skipped.",
            annot))
        return {}
    else
        return annot_fn(source, dest, annot_parms)
    end
end

function recursive_insert_word(insertion_point, remaining_words, item, level)
    -- If there is only one word left, insert the item at the insertion point.
    -- If the source is a single word, this is all that will run and we don't
    -- get into the recursive part.
    local this_word = string.lower(remaining_words[1])
    if #remaining_words == 1 then
        if insertion_point[this_word] == nil then
            insertion_point[this_word] = item
        else
            -- Preserve existing continuation entry if it doesn't exist.
            local existing_cont = insertion_point[this_word].continuation
            item.continuation = existing_cont
            insertion_point[this_word] = item
        end
        return
    end

    -- There is more than one word left. This means we need to enter a
    -- continuation on this table entry. If the table entry, or its
    -- continuation, doesn't exist, we need to create it.
    if insertion_point[this_word] == nil then
        insertion_point[this_word] = {continuation = {}}
    elseif insertion_point[this_word].continuation == nil then
        insertion_point[this_word].continuation = {}
    end

    -- Now the continuation becomes our insertion point and we try again.
    if level == nil then
        level = 1
    end
    table.remove(remaining_words, 1)
    return recursive_insert_word(
        insertion_point[this_word].continuation,
        remaining_words, item, level + 1)
end

function insert_mapping(lut, source, dest, item)
    if #item.dest > #source then
        print(string.format(
            "WARNING: Destination '%s' is longer than source '%s' on line %d: %s",
            item.dest, source, item.line, item.directive))
    end

    local existing_item = lut[source:lower()]
    if existing_item == nil then  -- entry doesn't exist yet
        recursive_insert_word(lut, util.split_whitespace(source), item)
    elseif existing_item.dest == nil then  -- a continuation-only entry exists
        local existing_cont = existing_item.continuation
        recursive_insert_word(lut, util.split_whitespace(source), item)
        item.continuation = existing_cont
    else  -- this source has already been mapped
        if not item.flags:match("-") then
            print(string.format(
                "WARNING: Ignoring remapping of source '%s' on line %d: %s",
                source, item.line, item.directive))
            print(string.format(
                "   note: previously mapped to '%s' on line %d: %s",
                existing_item.dest, existing_item.line, existing_item.directive))
        end
    end
end

function source_parts(item)
    local elts = {}
    for i in string.gmatch(item.source, "[^,]*") do
        if i == nil then
            print(string.format(
                "WARNING: Invalid source directive on line %d: %s",
                item.line, item.source))
        elseif not string.match(i, "^%s*[-'’%w%s]+%s*$") then
            print(string.format(
                "WARNING: Source directive is not alphanumeric on line %d "
                .. "and will be ignored: %s",
                item.line, item.source))
        else
            table.insert(elts, util.trim(i))
        end
    end
    return #elts == 0 and {item.source} or elts
end


function lut_entries_from_item(lut, item)
    for _, inner_source in ipairs(source_parts(item)) do
        local my_item = util.shallow_copy(item)
        insert_mapping(lut, inner_source, item.dest, my_item)

        local exploded = explode_annot(inner_source, item.dest, item.annot)
        if exploded ~= nil then
            for exp_source, exp_dest in pairs(exploded) do
                if exp_source ~= inner_source then
                    -- If the same, an annotation resulted in an identical value
                    -- to the root (e.g., 'read => ris @v' does this).
                    -- We don't want a warning in this case!
                    new_item = util.shallow_copy(item)
                    new_item.source = exp_source
                    new_item.dest = exp_dest
                    insert_mapping(lut, exp_source, exp_dest, new_item)
                end
            end
        end
    end
end

function is_comment(line)
    return util.trim(line):sub(1, 1) == '#'
end

function needs_print(item)
    -- An item needs to be printed in a trace if it has a ? flag or if any child does.
    if item.flags ~= nil and item.flags:match("%?") then
        return true
    end
    if item.continuation ~= nil then
        for _, child_item in pairs(item.continuation) do
            if needs_print(child_item) then
                return true
            end
        end
    end
    return false
end

function print_tracing(lut)
    local prints = {}
    for k, v in pairs(lut) do
        if needs_print(v) then
            table.insert(prints, k .. ' => ' .. inspect(v))
        end
    end

    if #prints > 0 then
        local ess = (#prints == 1) and '' or 's'
        print("WARNING: At least one trace flag was found in the dictionary.")
        print(string.format(
            "Traced replacements for %d root node%s and children:",
            #prints, ess))
        for _, v in ipairs(prints) do
            print(v)
        end
    end
end

function build_lut(filename)
    local lut = {}
    idx = 1
    f = io.open(filename)
    for directive in f:lines() do
        if not util.is_nil_or_whitespace(directive) and not is_comment(directive) then
            local flags, source, dest, annot = directive:match(
                    "([-%+%?%!]*)(.-)%s*=>%s*([^@]*)(.*)")
            if source == nil or dest == nil then
                print(string.format("WARNING: Ignoring invalid line %d: %s", idx, directive))
            else
                lut_entries_from_item(lut, {
                    directive = directive,
                    flags     = flags,
                    source    = source,
                    dest      = util.trim(dest),
                    annot     = util.trim(annot),
                    line      = idx
                })
                if flags:match("%!") then
                    print(string.format(
                        "WARNING: Cut found on line %d, skipping rest of dictionary.",
                        idx))
                    break
                end
            end
        end
        idx = idx + 1
    end
    f:close()

    -- TODO: Benchmark this and see if there's benefit in including a flag
    -- that indicates whether any tracing entries were made, without which we can skip
    print_tracing(lut)

    return lut
end

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

    -- Work down the list of tokens. At each iteration, greedily consume one
    -- or more matching tokens and advance loop counter by the number of tokens
    -- consumed.
    local tersened = {}
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
        return result, #text, #result, #result/#text
    end
end

local lut = build_lut("full_tersen.txt")
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
