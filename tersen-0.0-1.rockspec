package = "tersen"
version = "0.0-1"
source = {
    url = "...",
}
description = {
    summary = "Fast, flexible, small abbreviation engine",
    detailed = [[
        I am tersen.
    ]],
    homepage = "...",
    license = "...",
}
dependencies = {
    "lua >= 5.3, < 5.5",
    "argparse >= 0.7.1",
    "inspect >=3.1.1",
}
build = {
    type = "builtin",
    modules = {
        ["tersen.case"] = "tersen/case.lua",
        ["tersen.hook_exec"] = "tersen/hook_exec.lua",
        ["tersen.lut"] = "tersen/lut.lua",
        ["tersen.main"] = "tersen/main.lua",
        ["tersen.tersen"] = "tersen/tersen.lua",
        ["tersen.trace"] = "tersen/trace.lua",
        ["tersen.util"] = "tersen/util.lua",
        ["tersen.extend.annot"] = "tersen/extend/annot.lua",
        ["tersen.extend.hooks"] = "tersen/extend/hooks.lua",
    }
}