local argparse = require 'argparse'
local inspect = require 'inspect'  -- DEBUG
local lut_mod = require 'lut'
local tersen_mod = require 'tersen'
local trace_mod = require 'trace'
local util = require 'util'


local function refold(str, cols)
    local lines = {}

    for paragraph in str:gmatch("(.-)\n\n+") do
        local cur_line = {}
        local at_char = 0

        for _, word in ipairs(util.split_whitespace(paragraph)) do
            --TODO: super-long word handling
            if at_char + #word + 1 > cols then
                table.insert(lines, table.concat(cur_line, " "))
                cur_line = {}

                table.insert(cur_line, word)
                at_char = #word
            else
                table.insert(cur_line, word)
                at_char = at_char + #word + 1
            end
        end

        table.insert(lines, table.concat(cur_line, " "))
        table.insert(lines, "")
    end
    return table.concat(lines, "\n")
end


-- Get an operation callable that takes (lut, text).
local function get_callable(args)
    if args.frequency then
        return function(lut, text)
            tersen_mod.print_unmatched_tokens(tersen_mod.unmatched_in_corpus(lut, text))
        end
    else
        return tersen_mod.tersen
    end
end


local function get_parser()
    local parser = argparse {
        name = "tersen",
        description = "tersen - the fast, flexible abbreviation engine",
        epilog = "Soren Bjornstad",
    }
    parser:argument(
        "tersen_dict",
        "Path to the tersen dictionary containing abbreviation mappings.")
    parser:argument(
        "files_to_tersen",
        "Text file(s) to be tersened; use - for stdin.")
        :args("+")
    parser:flag(
        "-w --width",
        "Number of columns to re-fold the result to. Only useful with -o.")
        :args("1")
        :convert(tonumber)
    parser:flag(
        "-f --frequency",
        "Instead of tersening input, analyze what would have been tersened "
        .. "and print out the most frequently used words that don't have "
        .. "abbreviations. ")
    parser:flag(
        "-o --at-once",
        "Instead of reading a line at a time, read and process all input in a chunk.")
    return parser
end

local parser = get_parser()
local args = parser:parse()

local lut = lut_mod.build_from_dict_file(args.tersen_dict)
trace_mod.trace(lut)
for _, v in ipairs(args.files_to_tersen) do
    local f
    if v == '-' then
        f = io.stdin
    else
        f = io.open(v)
    end

    if args.at_once then
        local text = f:read("*a")
        local res = get_callable(args)(lut, text)
        if args.width ~= nil then
            print(refold(res, args.width))
        else
            print(res)
        end
    else
        for line in f:lines() do
            local res = get_callable(args)(lut, line)
            print(res)
        end
    end

    if f ~= io.stdin then
        f:close()
    end
end
os.exit(1)

local lut = lut_mod.build_from_dict_file("tersen_dict.txt")
--local lut = lut_mod.build_from_dict_file("full_tersen.txt")
trace_mod.trace(lut)
--print(inspect(lut))
--local myfile = io.open("/home/soren/random-thoughts.txt")
--local unmatched = tersen_mod.unmatched_in_corpus(lut, myfile:read("*a"))
--tersen_mod.print_unmatched_tokens(unmatched)
--os.exit(1)

os.exit(1)
local input = io.open("/home/soren/random-thoughts.txt")
local orig_tot, new_tot = 0, 0
for i in input:lines() do
    local result, orig, new = tersen_mod.tersen(lut, i)
    print(result)
    orig_tot = orig_tot + orig
    new_tot = new_tot + new
end

print("Stats:", orig_tot, new_tot, new_tot / orig_tot)
