Quick start
===========

Want to get your hands dirty with tersen?
You've come to the right place!

1. If you have not done so already, install Lua and LuaRocks,
   then run ``luarocks install tersen`` to install tersen.

2. Copy the following to a new text file and save it as ``tersen_dict.txt``:
   ::

        and => &
        with => w/
        without => w/o
        Personal Identification Number => PIN @n_acro

   This is a :ref:`dictionary <The tersen dictionary format>`,
   which explains how words are abbreviated
   in your preferred abbreviation system.

   Each line is called a :ref:`mapping <Mappings>`.
   The part of a mapping before the ``=>`` is called a :ref:`source <Sources>`,
   and is what tersen will try to replace in your input file.
   The part after the ``=>`` and before the ``@`` or line break
   is called a :ref:`destination <Destinations>`,
   and is what tersen will replace the source with
   when it encounters the source in your input file.

   The bit starting with an ``@`` is an :ref:`annotation <Annotations>`;
   that causes tersen to add a plural form of the acronym,
   so that it knows how to abbreviate
   ``Personal Identification Numbers`` to ``PINs`` as well.

3. Create a test input file containing one or more of the source phrases above
   and save it as ``test.txt``.

4. Run tersen:
   ::

        $ tersen tersen_dict.txt test.txt

   An abbreviated version of your test file will be printed to the terminal.
   The first argument to ``tersen`` is the dictionary file;
   any number of input files can be specified thereafter,
   and tersen will read them in turn
   and print the tersened versions to standard output.


At this point, you are ready to build up a dictionary for your preferred system.
Check out :ref:`Terms` and :ref:`The tersen dictionary format`
if you get mixed up about the syntax of the dictionary file
or how punctuation is handled.
If you are building a complex dictionary,
you may also want to read about
:ref:`annotations <Annotations>` and :ref:`hooks <Hooks>`
before you get too far in,
as they may allow you to simplify your dictionary somewhat.
