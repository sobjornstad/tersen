inspect = require 'inspect'  -- DEBUG

function trim(str)
    return string.match(str, "^%s*(.-)%s*$")
end

function split_source(source)
    local elts = {}
    for i in string.gmatch(source, "[^,]*") do
        table.insert(elts, trim(i))
    end
    print(inspect(elts))
    return #elts == 0 and {source} or elts
end

function build_lut(filename)
    local lut = {}
    f = io.open(filename)
    for directive in f:lines() do
        source, dest = string.match(directive, "(.-)%s*=>%s*(.*)")
        if source == nil or dest == nil then
            print("WARNING: Invalid line - " .. directive)
        else
            for _, inner_source in ipairs(split_source(source)) do
                lut[inner_source] = dest
            end
        end
    end
    f:close()
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
        initial, munged_word, final = munge_input(word)
        prospective_repl = lut[munged_word]
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
