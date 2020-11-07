local js = require "js"
local window = js.global
local lut_mod = require 'lut'
local trace_mod = require 'trace'
local tersen_mod = require 'tersen'

local function elem(name)
    return window.document:getElementById(name)
end

local submit = elem("submit")

function submit:onclick(e)
    e:preventDefault()

    elem("processing").style["display"] = "inline"

    local dict_str = elem("tersen_dict").value
    local lut = lut_mod.build_from_string(dict_str)
    trace_mod.trace(lut)

    local result = tersen_mod.tersen(lut, elem("verbose_text").value)
    elem("results").innerText = result

    elem("processing").style["display"] = "none"
end
