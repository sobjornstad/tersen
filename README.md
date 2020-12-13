# Tersen

**Tersen** is a *fast, flexible abbreviation engine*
    that compresses text in a human-readable fashion.
Abbreviations are entirely user-specifiable
    through a dictionary of textual mappings (e.g., `and` becomes `&`).
More concise dictionary files and custom abbreviation behavior
    can be obtained by writing Lua functions called
    *annotations* (which pre-process lines in the abbreviation dictionary)
    and *hooks* (which alter tersen's behavior as it abbreviates a text).

Use cases for tersen include:

* Packing more information onto a cheat sheet or reference guide.
* Sending content over SMS or another limited-bandwidth communication channel.
* Obfuscating content so others cannot easily read it but you can.
* Practicing your reading skills in your favorite alphabetic shorthand system.

Tersen is written and extended in Lua.
It uses the MIT license.


## Installation

Lua and [LuaRocks](https://luarocks.org) are required to run tersen.

Direct installation via LuaRocks is recommended in most cases:

```
luarocks install tersen
```

For development,
clone this repository and run `make`;
LuaRocks will then install tersen from the sources.

In either case, ``tersen`` will then be installed on your system path.


## Documentation

Complete documentation can be found on Read the Docs (TODO link).
A quick-start guide is included (TODO link).
