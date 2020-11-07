local annotation_functions = require 'tersen.extend.annot'
local util = require 'tersen.util'

local M = {}


-- Given an annotation string (the part beginning with @),
-- return its name (string) and its parameters (list of strings).
local function parse_annot(annot)
    local annot_name, annot_parmstart = annot:match("^@([%w_]+)([%[%{]?)")

    local annot_parms
    if util.is_nil_or_whitespace(annot_parmstart) then
        annot_parms = nil
    elseif annot_parmstart == '[' then
        annot_parms = util.split_whitespace(annot:match("^@[%w_]+%[(.*)%]"))
    elseif annot_parmstart == '{' then
        local parm_string = annot:match("^@[%w_]+%{(.*)}"):gsub('}{', '\0')
        annot_parms = {}
        for i in string.gmatch(parm_string, "[^\0]+") do
            table.insert(annot_parms, i)
        end
    else
        error("Oops, this should never happen: annot_parmstart was '"
              .. annot_parmstart .. "'")
    end

    return annot_name, annot_parms
end


-- Apply an annotation function defined in annot.lua to the source => dest mapping,
-- returning a table of one or more new source => dest mappings.
function M.explode(item)
    local annot_name, annot_parms = parse_annot(item.annot)

    if annot_name == nil then
        print(string.format(
            "WARNING: Missing annotation name (@something) on mapping %s => %s. "
            .. "This mapping will be skipped.", item.source, item.dest))
        return {}
    end

    local annot_fn = annotation_functions[annot_name:lower()]
    if annot_fn == nil then
        print(string.format(
            "WARNING: Attempt to call a nonexistent annotation '%s'. This line will be skipped.",
            item.annot))
        return {}
    end

    return annot_fn(item.source, item.dest, annot_parms)
end

function M.set_annot_file(filename)
    if filename then
        annotation_functions = loadfile(filename)()
    end
end


return M
