local argparse = require 'argparse'
local inspect = require 'inspect'  -- DEBUG

local annot_exec = require 'tersen.annot_exec'
local hook_exec = require 'tersen.hook_exec'
local lut_mod = require 'tersen.lut'
local oops = require 'tersen.oops'
local tersen_mod = require 'tersen.tersen'
local trace_mod = require 'tersen.trace'
local util = require 'tersen.util'


local function fold_paragraph(paragraph_str, cols)
    local lines = {}
    local cur_line = {}
    local at_char = 0

    for _, word in ipairs(util.split_whitespace(paragraph_str)) do
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
    return lines
end


local function refold(str, cols)
    local lines = {}
    for _, paragraph in ipairs(util.split_paragraphs(str)) do
        local inner_lines = fold_paragraph(paragraph, cols)
        table.move(inner_lines, 1, #inner_lines, #lines + 1, lines)
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
    parser:option(
        "-a --annot",
        "Path to a file of annotations to be used instead of the default.")
    parser:flag(
        "-f --frequency",
        "Instead of tersening input, analyze what would have been tersened "
        .. "and print out the most frequently used words that don't have "
        .. "abbreviations. ")
    parser:option(
        "-h --hooks",
        "Path to a file of hooks to be used instead of the default.")
    parser:flag(
        "-o --at-once",
        "Instead of reading a line at a time, read and process all input in a chunk.")
    parser:option(
        "-w --width",
        "Re-fold paragraphs to the specified line width in columns. "
        .. "Only useful with -o.")
        :convert(tonumber)
    parser:flag(
        "-W --warnings-are-errors",
        "Stop tersen prior to tersening anything if warnings are encountered.")
    return parser
end

local function rc_args_from_file(filename)
    local rc_file = io.open(filename)
    if rc_file then
        local rc_text = rc_file:read("*a")
        rc_file:close()
        return util.split_newlines(rc_text)
    end
end

local function get_args()
    local home = os.getenv("HOME")
    local homepath = os.getenv("HOMEPATH")
    local rc_args = nil
    if home ~= nil then
        rc_args = rc_args_from_file(home .. "/.tersenrc")
    elseif homepath ~= nil then
        rc_args = rc_args_from_file(home .. "\\.tersenrc")
    end

    local complete_args = {}
    if rc_args ~= nil then
        table.move(rc_args, 1, #rc_args, 1, complete_args)
    end
    table.move(arg, 1, #arg, #complete_args + 1, complete_args)

    return complete_args
end


local parser = get_parser()
local args = parser:parse(get_args())

hook_exec.set_hook_file(args.hooks)
annot_exec.set_annot_file(args.annot)

local lut = lut_mod.build_from_dict_file(args.tersen_dict)
trace_mod.trace(lut)

if args.warnings_are_errors and oops.num_warnings() > 0 then
    print(oops.num_warnings()
          .. " warnings encountered. Failing because --warnings-are-errors was set.")
    os.exit(1)
end

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
