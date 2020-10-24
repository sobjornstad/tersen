local inspect = require 'inspect'  -- DEBUG
local util = require 'util'


function explode_annot(source, dest, annot)
    local annot_type, annot_content = annot:match("^@(%w+)%[([%w%s]+)%]")
    if annot_type == nil and annot_content == nil then
        annot_type = annot:match("^%s*@(%w+)$")
        if annot_type == nil then
            return nil
        end
    end

    local type_switch = {
        adj = function(annot_parts)
            local comparative, superlative
            if annot_parts == nil then
                if string.sub(source, -1, -1) == "e" then
                    comparative = source .. "r"
                    superlative = source .. "st"
                else
                    comparative = source .. "er"
                    superlative = source .. "est"
                end
            else
                comparative, superlative = table.unpack(annot_parts)
            end
            return {[comparative] = "me" .. dest, [superlative] = "my" .. dest}
        end,
        n = function(annot_parts)
            local plural
            if annot_parts == nil then
                if string.sub(source, -1, -1) == "s" then
                    plural = source .. "es"
                elseif string.sub(source, -1, -1) == "y" then
                    plural = source.sub(source, 1, -2) .. "ies"
                else
                    plural = source .. "s"
                end
            else
                plural = annot_parts[1]
            end
            return {[plural] = dest .. "z"}
        end,
        v = function(annot_parts)
            local third, past, perfect, participle
            if annot_parts == nil then
                if util.is_vowel(source:sub(-1, -1)) then
                    past = source .. "d"
                    participle = source:sub(1, -2) .. "ing"
                else
                    past = source .. "ed"
                    participle = source .. "ing"
                end
                perfect = past
                third = source .. "s"
            else
                third, past, perfect, participle = table.unpack(annot_parts)
            end
            -- If any are the same, they will be silently collapsed.
            return {[third] = dest,
                    [past] = "y" .. dest,
                    [perfect] = dest .. "d",
                    [participle] = "u" .. dest}
        end,
    }
    return type_switch[annot_type](util.split_whitespace(annot_content))
end

function insert_mapping(lut, source, dest, item)
    if lut[source] ~= nil then
        print(string.format(
            "WARNING: Ignoring remapping of source '%s' on line %d: %s",
            source, item.line, item.directive))
        print(string.format(
            "   note: previously mapped to '%s' on line %d: %s",
            lut[source].dest, lut[source].line, lut[source].directive))
    else
        if #item.dest > #source then
            print(string.format(
                "WARNING: Destination '%s' is longer than source '%s' on line %d: %s",
                item.dest, source, item.line, item.directive))
        end
        lut[source] = item
    end
end

function source_parts(item)
    local elts = {}
    for i in string.gmatch(item.source, "[^,]*") do
        if i == nil then
            print(string.format(
                "WARNING: Invalid source directive on line %d: %s",
                item.line, item.source))
        else
            table.insert(elts, util.trim(i))
        end
    end
    return #elts == 0 and {item.source} or elts
end


function lut_entries_from_item(lut, item)
    for _, inner_source in ipairs(source_parts(item)) do
        insert_mapping(lut, inner_source, item.dest, item)

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

function build_lut(filename)
    local lut = {}
    idx = 1
    f = io.open(filename)
    for directive in f:lines() do
        if not is_nil_or_whitespace(directive) and not is_comment(directive) then
            local source, dest, annot = string.match(directive, "(.-)%s*=>%s*([^@%s]*)(.*)")
            if source == nil or dest == nil then
                print(string.format("WARNING: Ignoring invalid line %d: %s", idx, directive))
            else
                item = {directive = directive, source = source, dest = dest,
                        annot = util.trim(annot), line = idx}
                lut_entries_from_item(lut, item)
            end
        end
        idx = idx + 1
    end
    f:close()
    return lut
end

function greeken(str)
    local gk_tab = {
        ["ment"] = "μ",
        ["tion"] = "σ",
        ["com"] = "κ",
        ["con"] = "κ",
        ["ship"] = "π",
        ["ing"] = "γ",
        ["ally"] = "λ",
        ["lly"] = "λ",
        ["ly"] = "λ",
    }
    -- TODO: This needs to go in order in the actual implementation
    for search, repl in pairs(gk_tab) do
        str = string.gsub(str, search, repl)
    end
    return str
end

function munge_input(word)
    initial_part, word_part, final_part = string.match(word, "(%W*)(%w+)(%W*)")
    if initial_part == nil or word_part == nil or final_part == nil then
        return nil, word, nil
    else
        return initial_part, word_part, final_part
    end
end

function tersen(lut, text, stats)
    local tersened = {}
    for word in string.gmatch(text, "%S+") do
        local initial, munged_word, final = munge_input(word)
        local prospective_repl = lut[munged_word]
        if prospective_repl == nil then
            table.insert(tersened, greeken(word))
        else
            table.insert(tersened, initial .. prospective_repl.dest .. final)
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
for i in input:lines() do
    print(tersen(lut, i))
end
--print(tersen(lut, "Soren and Maud went to the store and it was easy."))

-- TODO: Hyphenated words appear to work incorrectly
-- TODO: Handle capitalization better
-- TODO: Multi-word phrases using a "continuation" element in the hash
-- TODO: Unicode normalization?
