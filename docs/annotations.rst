Annotations
===========

*Annotations* are Lua functions
that transform the source and destination of a mapping in an arbitrary way.
An annotation can output one mapping or many mappings;
for instance, you might wish to add both the singular form
and a plural form of a word using an annotation.
Several annotations are provided with tersen,
and you can easily write your own.


Dictionary syntax
-----------------

The details of how annotations are written in the dictionary
can be found at :ref:`Annotated mappings`.


Built-in annotations
--------------------

The following annotations are included with tersen.

``n_acro``
    Apply to an acronym to allow tersen to recognize its English plural form as well.
    For example:
    ::

        Personal Identification Number => PIN @n_acro
    
    This will add an extra entry mapping ``Personal Identification Numbers`` to ``PINs``.
    
    If the plural were not ``Personal Identification Numbers``,
    but, say, ``People Identification Number``,
    you could list the source's plural form as an argument:
    ::

        Personal Identification Number => PIN @n_acro{People Identification Number}

``apos``
    Apply to a word containing an apostrophe
    so that it works with both curly and straight apostrophes.
    For example:
    ::

        you're => v_e @apos

    This will add entries mapping both ``you're`` and ``you’re`` to ``v_e``.

``numbers``
    Ignore the provided source and destination
    and instead add entries mapping the English numbers
    from ``one`` to ``ninety-nine``
    to the Arabic numerals from ``1`` to ``99``.


.. attention::
    If you specify a custom annotations file with the ``-a`` option to tersen,
    you need to include these default annotations in that custom annotations file
    or they will not be accessible.
    See :ref:`Backing functions`, below, for more details on creating such a file.


Backing functions
-----------------

Annotations are processed by Lua functions
in the ``M`` table in the ``tersen/extend/annot.lua`` file in the tersen distribution.
The name of the function
is the name used to access the annotation in the tersen dictionary,
and may contain lowercase letters, numbers, and underscores
(annotations in the tersen dictionary are flattened to lowercase,
so if you use uppercase in your name it will be impossible to call it).

If you want to add your own annotations, you should
start from a copy of this file,
putting it somewhere convenient
and telling tersen to use it with the ``-a annotationfile`` argument at runtime.
If you don't want to type this every time you run tersen,
:ref:`set up <tersenrc>` a ``.tersenrc``.

.. todo::
    Provide a GitHub link


Function details
----------------

Each annotation function takes three arguments:
the source listed in the tersen dictionary,
the destination listed in the tersen dictionary,
and a list of arguments to the annotation
(as a table with numeric keys, or ``nil`` if the annotation was argumentless).
It returns a table of mappings,
the keys being sources and the values being destinations.

If there are multiple comma-separated sources,
the annotation function is called separately for each source.

Here’s a simple example, the built-in function for ``@apos``,
which ensures that any apostrophes in the source value
get dictionary entries for both curly apostrophes and straight apostrophes.

.. code-block:: lua

    function M.apos (source, dest, args)
        local straight = string.gsub(source, "'", "’")
        local curly = string.gsub(source, "’", "'")
        return {[straight] = dest, [curly] = dest}
    end

It’s possible to use an annotation to programmatically generate some entries
without using the mapping at all.
For instance, the built-in ``@numbers`` annotation
adds entries for the words “one” through “ninety-nine”
and their corresponding digit representations.
To include the output of such an annotation in your dictionary,
simply put a dummy source and replacement on a line
and attach the annotation, like so:
::

    Numbers as Words => Digits @numbers

You can trace this line to see the effect if you like,
by placing a `?` in front of it (see *Flags*, below).

If you find this to be an ugly abuse of annotations,
you can also get the programmatic-generation effect
using the ``post_build_lut`` :ref:`hook <Hooks>`.
