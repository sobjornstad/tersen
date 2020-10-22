inspect = require 'inspect'  -- DEBUG

function build_lut(filename)
    local lut = {}
    lut['Maud'] = "Md."
    lut['Soren'] = "S."
    lut['and'] = "&"
    return lut
end

function tersen(lut, text)
    local tersened = {}
    for word in string.gmatch(text, "%S+") do
        prospective_repl = lut[word]
        if prospective_repl == nil then
            table.insert(tersened, word)
        else
            table.insert(tersened, prospective_repl)
        end
    end
    return table.concat(tersened, " ")
end

local lut = build_lut("tersen_dict.txt")
print(tersen("Soren and Maud went to the store."))
