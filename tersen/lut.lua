local annot_exec = require 'tersen.annot_exec'
local hook = require 'tersen.hook_exec'
local util = require 'tersen.util'

local M = {}

---------- Utilities ----------
-- If the destination is longer than the source, warn, or take whatever other action
-- is defined in the appropriate hook.
local function handle_longer_destination(item)
    if #item.dest > #item.source then
        local new_source, new_dest = hook
            .try_invoke("mapping_verbosens_text", item.source, item.dest, item)
            :or_execute(function()
                print(string.format(
                    "WARNING: Destination '%s' is longer than source '%s' on line %d: %s",
                    item.dest, item.source, item.line, item.directive))
                return item.source, item.dest
            end)
        if new_source == nil or new_dest == nil then
            return
        else
            item.source, item.dest = new_source, new_dest
        end
    end
end


-- Split a source (the part before => in a directive line)
-- into its constituent comma-separated parts and return a list thereof.
local function source_parts(item)
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


---------- Insertion ----------
-- Add an entry for a word to the lut (or continuation) at insertion_point.
local function insert_word_here(insertion_point, word, item)
    if insertion_point[word] == nil then
        insertion_point[word] = item
    else
        -- Preserve an existing continuation if it exists without a full word.
        local existing_cont = insertion_point[word].continuation
        item.continuation = existing_cont
        insertion_point[word] = item
    end
end


-- Insert a series of tokens at /insertion_point/. If there's more than one token,
-- we recurse into the 'continuation' property of the first token, creating it if
-- it doesn't exist, and work from there.
local function insert_word_recursively(insertion_point, remaining_words, item, level)
    local current_word = string.lower(remaining_words[1])

    -- If there is only one word, insert the item at the insertion point.
    if #remaining_words == 1 then
        insert_word_here(insertion_point, current_word, item)
        return
    end

    -- There is more than one word left, so we need to put a continuation on
    -- this table entry. If the table entry, or its continuation, doesn't exist,
    -- we need to create it.
    if insertion_point[current_word] == nil then
        insertion_point[current_word] = {continuation = {}}
    elseif insertion_point[current_word].continuation == nil then
        insertion_point[current_word].continuation = {}
    end

    -- Now the continuation becomes our insertion point and we try again.
    if level == nil then
        level = 1
    end
    table.remove(remaining_words, 1)
    return insert_word_recursively(
        insertion_point[current_word].continuation,
        remaining_words, item, level + 1)
end


-- Add an entirely new item.
local function insert_new_entry(lut, item)
    insert_word_recursively(lut, util.split_whitespace(item.source), item)
end


-- Extend or edit an existing item while preserving its continuation.
local function extend_continuation_entry(lut, item, existing_item)
    local existing_cont = existing_item.continuation
    insert_word_recursively(lut, util.split_whitespace(item.source), item)
    item.continuation = existing_cont
end


-- If the suppress-warnings flag isn't on, warn user of a remap attempt
-- that wasn't intercepted by the mapping_conflicts hook.
local function warn_already_mapped(lut, item, existing_item)
    if not item.flags:match("-") then
        print(string.format(
            "WARNING: Ignoring remapping of source '%s' on line %d: %s",
            item.source, item.line, item.directive))
        print(string.format(
            "   note: previously mapped to '%s' on line %d: %s",
            existing_item.dest, existing_item.line, existing_item.directive))
    end
end


-- Add a mapping from /source/ to /dest/ in the lookup table.
local function new_mapping(lut, item)
    handle_longer_destination(item)
    local existing_item = lut[item.source:lower()]

    -- Check for conflicts and decide what to do.
    if existing_item ~= nil and existing_item.dest ~= nil then
        local do_remap = hook.try_invoke("mapping_conflicts", item, existing_item)
            :or_return(nil)
        if do_remap == nil then
            warn_already_mapped(lut, item, existing_item)
            return
        elseif do_remap == false then
            return
        -- If true (overwrite existing mapping), continue.
        end
    end

    if existing_item == nil then
        insert_new_entry(lut, item)
    else
        extend_continuation_entry(lut, item, existing_item)
    end
end


-- Given an item table containing one or more sources, a destination,
-- and perhaps an annotation, add mappings to the lookup table.
local function lut_entries_from_item(lut, item)
    for _, inner_source in ipairs(source_parts(item)) do
        if util.is_nil_or_whitespace(item.annot) then
            local inner_item = util.shallow_copy(item)
            inner_item.source = inner_source
            new_mapping(lut, inner_item)
        else
            local exploded = annot_exec.explode(item)
            for exploded_source, exploded_dest in pairs(exploded) do
                local new_item = util.shallow_copy(item)
                new_item.source = exploded_source
                new_item.dest = exploded_dest
                new_mapping(lut, new_item)
            end
        end
    end
end


---------- Parsing ----------
-- A tersen dictionary line is a comment if its first non-whitespace character is #.
local function is_comment(line)
    return util.trim(line):sub(1, 1) == '#'
end


-- Parse a dictionary directive and call lut_entries_from_item to add mappings to the table.
-- Return "cut" if processing should stop here due to a cut flag, nil otherwise.
local function lut_entries_from_directive(lut, directive, line_num)
    local flags, source, dest, annot = directive:match(
            "([-%+%?%!]*)(.-)%s*=>%s*([^@]*)(.*)")
    if source == nil or dest == nil then
        print(string.format(
            "WARNING: Ignoring invalid line %d: %s",
            line_num, directive))
        return nil
    end

    lut_entries_from_item(lut, {
        directive = directive,
        flags     = flags,
        source    = source,
        dest      = util.trim(dest),
        annot     = util.trim(annot),
        line      = line_num
    })

    if flags:match("%!") then
        print(string.format(
            "WARNING: Cut found on line %d, skipping rest of dictionary.",
            line_num))
        return "cut"
    end

    return nil
end


-- Given the path to a file containing a tersen dictionary,
-- build and return a tersen lookup table.
function M.build_from_dict_file(filename)
    local lut = {}
    local line_num = 1

    local f = io.open(filename)
    for directive in f:lines() do
        if not util.is_nil_or_whitespace(directive) and not is_comment(directive) then
            local result = lut_entries_from_directive(lut, directive, line_num)
            if result == "cut" then
                break
            end
        end
        line_num = line_num + 1
    end
    f:close()

    return hook.try_invoke("post_build_lut", lut)
        :or_return(lut)
end

function M.build_from_string(str)
    local lut = {}
    local line_num = 1

    for directive in str:gmatch("[^\n]*") do
        if not util.is_nil_or_whitespace(directive) and not is_comment(directive) then
            local result = lut_entries_from_directive(lut, directive, line_num)
            if result == "cut" then
                break
            end
        end
        line_num = line_num + 1
    end

    return hook.try_invoke("post_build_lut", lut)
        :or_return(lut)
end

return M
