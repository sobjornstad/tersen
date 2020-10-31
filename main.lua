local inspect = require 'inspect'  -- DEBUG
local lut_mod = require 'lut'
local tersen_mod = require 'tersen'

local lut = lut_mod.build_from_dict_file("full_tersen.txt")
lut_mod.trace(lut)

--local myfile = io.open("/home/soren/random-thoughts.txt")
--local unmatched = tersen_mod.unmatched_in_corpus(lut, myfile:read("*a"))
--tersen_mod.print_unmatched_tokens(unmatched)
--os.exit(1)
--local lut = build_lut("tersen_dict.txt")
--print(inspect(lut))

local input = io.open("/home/soren/random-thoughts.txt")
local orig_tot, new_tot = 0, 0
for i in input:lines() do
    local result, orig, new = tersen_mod.tersen(lut, i)
    print(result)
    orig_tot = orig_tot + orig
    new_tot = new_tot + new
end

print("Stats:", orig_tot, new_tot, new_tot / orig_tot)

-- TODO: Unicode normalization?
-- TODO: Convert to title case properly if there is punctuation earlier; ideally each word too
-- TODO: Newline handling
-- TODO: Allow applying multiple annotations
-- TODO: Force case sensitivity?
-- TODO: Improve warnings (print to stderr, give more details)

-- TODO: Annotations incorrectly add the non-annotated part without passing through
-- TODO: insert_mapping may not work correctly when the destination is set differently for different annotation returns...it appears to use the raw item for that.