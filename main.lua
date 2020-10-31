local inspect = require 'inspect'  -- DEBUG
local lut_mod = require 'lut'
local tersen_mod = require 'tersen'
local trace_mod = require 'trace'

local lut = lut_mod.build_from_dict_file("tersen_dict.txt")
--local lut = lut_mod.build_from_dict_file("full_tersen.txt")
trace_mod.trace(lut)
--print(inspect(lut))
os.exit(1)
--local myfile = io.open("/home/soren/random-thoughts.txt")
--local unmatched = tersen_mod.unmatched_in_corpus(lut, myfile:read("*a"))
--tersen_mod.print_unmatched_tokens(unmatched)
--os.exit(1)

local input = io.open("/home/soren/random-thoughts.txt")
local orig_tot, new_tot = 0, 0
for i in input:lines() do
    local result, orig, new = tersen_mod.tersen(lut, i)
    print(result)
    orig_tot = orig_tot + orig
    new_tot = new_tot + new
end

print("Stats:", orig_tot, new_tot, new_tot / orig_tot)
