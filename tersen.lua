inspect = require 'inspect'  -- DEBUG

lut = {}
lut['Maud'] = "Md."
lut['Soren'] = "S."
lut['and'] = "&"

function tersen(text)
    local tersened = {}
    local lookup = lut
    for word in string.gmatch(text, "%S+") do
        prospective_repl = lookup[word]
        if prospective_repl == nil then
            table.insert(tersened, word)
        else
            table.insert(tersened, prospective_repl)
        end
    end
    return table.concat(tersened, " ")
end

print(tersen("Soren and Maud went to the store."))
