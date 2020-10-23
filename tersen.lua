inspect = require 'inspect'  -- DEBUG

function trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

function split_whitespace(str)
    if str == nil then
        return nil
    end

    local T = {}
    for i in string.gmatch(str, "%S+") do
        table.insert(T, i)
    end
    return T
end

function split_source(source)
    local elts = {}
    for i in string.gmatch(source, "[^,]*") do
        if i == nil then
            print("WARNING: Invalid source directive " .. source)
        else
            table.insert(elts, trim(i))
        end
    end
    return #elts == 0 and {source} or elts
end

function explode_annot(source, dest, annot)
    local annot_type, annot_content = annot:match("^%s*@(%w+)%[([%w%s]+)%]")
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
                comparative, superlative = source .. "er", source .. "est"
            else
                comparative, superlative = table.unpack(annot_parts)
            end
            return {[comparative] = "me" .. dest, [superlative] = "my" .. dest}
        end,
        n = function(annot_parts)
            local plural
            if annot_parts == nil then
                plural = source .. "s"
            else
                plural = annot_parts[1]
            end
            return {[plural] = dest .. "z"}
        end,
        v = function(annot_parts)
            local third, past, perfect, participle
            if annot_parts == nil then
                third = source .. "s"
                past = source .. "ed"
                perfect = source .. "ed"
                participle = source .. "ing"
            else
                third, past, perfect, participle = table.unpack(annot_parts)
            end
            return {[third] = dest,
                    [past] = "y" .. dest,
                    [perfect] = dest .. "d",
                    [participle] = "u" .. dest}
        end,
    }
    return type_switch[annot_type](split_whitespace(annot_content))
end

function build_lut(filename)
    local lut = {}
    f = io.open(filename)
    for directive in f:lines() do
        local source, dest, annot = string.match(directive, "(.-)%s*=>%s*([^@%s]*)(.*)")
        if source == nil or dest == nil then
            print("WARNING: Invalid line - " .. directive)
        else
            for _, inner_source in ipairs(split_source(source)) do
                if lut[inner_source] ~= nil then
                    print(string.format(
                        "WARNING: Ignoring remapping of source '%s': %s",
                        inner_source, directive))
                else
                    lut[inner_source] = dest
                end
            end
            -- TODO: Should probably be inner_source
            local exploded = explode_annot(source, dest, annot)
            if exploded ~= nil then
                for exp_source, exp_dest in pairs(exploded) do
                    lut[exp_source] = exp_dest
                end
            end
        end
    end
    f:close()
    print(inspect(lut))
    return lut
end

function munge_input(word)
    initial_part, word_part, final_part = string.match(word, "(%W*)(%w+)(%W*)")
    if initial_part == nil or word_part == nil or final_part == nil then
        return nil, word, nil
    else
        return initial_part, word_part, final_part
    end
end

function tersen(lut, text)
    local tersened = {}
    for word in string.gmatch(text, "%S+") do
        local initial, munged_word, final = munge_input(word)
        local prospective_repl = lut[munged_word]
        if prospective_repl == nil then
            table.insert(tersened, word)
        else
            table.insert(tersened, initial .. prospective_repl .. final)
        end
    end
    return table.concat(tersened, " ")
end

local lut = build_lut("tersen_dict.txt")
print(tersen(lut, "Soren and Maud went to the store."))
