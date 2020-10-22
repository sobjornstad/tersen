inspect = require 'inspect'  -- DEBUG

function build_lut(filename)
    local lut = {}
    lut['Maud'] = "Md."
    lut['Soren'] = "S."
    lut['and'] = "&"
    lut['store'] = "garp"
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
print(tersen("Soren and Maud went to the store."))
