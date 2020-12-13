tersen
======

**Tersen** is a *fast, flexible abbreviation engine*
that compresses text in a human-readable fashion.
Abbreviations are entirely user-specifiable
through a dictionary of textual mappings (e.g., ``and`` becomes ``&``).
More concise dictionary files and custom abbreviation behavior
can be obtained by writing Lua functions called
*annotations* (which pre-process lines in the abbreviation dictionary)
and *hooks* (which alter tersen's behavior as it abbreviates a text).

Use cases for tersen include:

* Packing more information onto a cheat sheet or reference guide.
* Sending content over SMS or another limited-bandwidth communication channel.
* Obfuscating content so others cannot easily read it but you can.
* Practicing your reading skills in your favorite alphabetic shorthand system.

Tersen is written and extended in `Lua`_.
It uses the MIT license.
You can install it using `LuaRocks`_:
::

    $ luarocks install tersen

.. _Lua: http://lua.org/
.. _LuaRocks: http://luarocks.org/


.. toctree::
   :maxdepth: 3
   :caption: Contents

   qstart
   terms-and-concepts
   dictionary
   annotations
   hooks
   cmdline
   implementation-details
