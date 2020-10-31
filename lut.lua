local annotation_functions = require 'annot'
local hook = require 'hook_exec'
local inspect = require 'inspect'  -- DEBUG
local util = require 'util'

local M = {}


-- A tersen dictionary line is a comment if its first non-whitespace character is #.
local function is_comment(line)
    return util.trim(line):sub(1, 1) == '#'
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


-- Given an annotation string (the part beginning with @),
-- return its name (string) and its parameters (list of strings).
local function parse_annot(annot)
    local annot_name, annot_parmstart = annot:match("^@([%w_]+)([%[%{]?)")

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

    return annot_name, annot_parms
end


-- Apply an annotation function defined in annot.lua to the source => dest mapping,
-- returning a table of one or more new source => dest mappings.
local function explode_annot(source, dest, annot)
    local annot_name, annot_parms = parse_annot(annot)

    if annot_name == nil then
        print(string.format(
            "WARNING: Missing annotation name (@something) on mapping %s => %s. "
            .. "This mapping will be skipped.", source, dest))
        return {}
    end

    local annot_fn = annotation_functions[annot_name:lower()]
    if annot_fn == nil then
        print(string.format(
            "WARNING: Attempt to call a nonexistent annotation '%s'. This line will be skipped.",
            annot))
        return {}
    end

    return annot_fn(source, dest, annot_parms)
end


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
local function recursive_insert_word(insertion_point, remaining_words, item, level)
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
    return recursive_insert_word(
        insertion_point[current_word].continuation,
        remaining_words, item, level + 1)
end


-- Add a mapping from /source/ to /dest/ in the lookup table.
local function insert_mapping(lut, source, dest, item)
    if #item.dest > #source then
        local new_source, new_dest = hook
            .try_invoke("mapping_verbosens_text", source, item.dest, item)
            :or_execute(function()
                print(string.format(
                    "WARNING: Destination '%s' is longer than source '%s' on line %d: %s",
                    item.dest, source, item.line, item.directive))
                return source, item.dest
            end)
        if new_source == nil or new_dest == nil then
            return
        else
            -- TODO: We probably should not be altering item;
            -- not using the dest param is probably a bug anyway;
            -- we should extract this if-statement bit into a new function then.
            source, item.dest = new_source, new_dest
        end
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


-- If an item exploded due to an annotation,
-- call here to add lookup entries based on the explosion.
local function lut_entries_from_explosion(lut, item, inner_source, exploded)
    for exploded_source, exploded_dest in pairs(exploded) do
        if exploded_source == inner_source then
            -- If the same, an annotation resulted in an identical value
            -- to the root (e.g., 'read => ris @v' does this).
            -- We don't want a warning in this case, so do nothing.
        else
            local new_item = util.shallow_copy(item)
            new_item.source = exploded_source
            new_item.dest = exploded_dest
            insert_mapping(lut, exploded_source, exploded_dest, new_item)
        end
    end
end


-- Given an item table containing one or more sources, a destination,
-- and perhaps an annotation, add mappings to the lookup table.
local function lut_entries_from_item(lut, item)
    for _, inner_source in ipairs(source_parts(item)) do
        local my_item = util.shallow_copy(item)
        insert_mapping(lut, inner_source, item.dest, my_item)

        if not util.is_nil_or_whitespace(item.annot) then
            local exploded = explode_annot(inner_source, item.dest, item.annot)
            lut_entries_from_explosion(lut, item, inner_source, exploded)
        end
    end
end


-- Parse a dictionary directive and call lut_entries_from_item to add mappings to the table.
-- Return "cut" if processing should stop here due to a cut flag, nil otherwise.
local function lut_entries_from_directive(lut, directive, line_num)
    local flags, source, dest, annot = directive:match(
            "([-%+%?%!]*)(.-)%s*=>%s*([^@]*)(.*)")
    if source == nil or dest == nil then
        print(string.format("WARNING: Ignoring invalid line %d: %s", line_num, directive))
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


-- An item needs to be printed in a trace if it has a ? flag or if any child does.
local function needs_print(item)
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


-- Print all items in the provided lookup table that have a trace flag on.
function M.trace(lut)
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

    hook.invoke("trace", lut)
end


-- Given the path to a file containing a tersen dictionary, return a
-- lookup-table structure that 
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

return M