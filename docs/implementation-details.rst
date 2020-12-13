Implementation details
======================

Most users will not care about these details
because tersen will just do the right thing.
However, if you're encountering odd behavior or you wish to extend tersen,
you might want to have a look at these notes.


Case
----

Tersen is case-insensitive when matching,
to the extent that your system locale
can lowercase the characters you’re working with.
When replacing a match,
tersen uses some simple rules to determine the case of the output:

* If the destination, as defined in the tersen dictionary, is all-caps,
  tersen assumes this is an acronym,
  and the output will always be all-caps.
* If the matched text itself was all-caps, its tersened output will be as well.
* If the matched text was title case,
  its tersened output will be in title case.
* Otherwise, the output will be whatever case the replacement is.

Though these rules are not always perfect,
for the most part, tersen will do the right thing with case.
If you find it is doing the wrong thing,
you can customize the rules via the ``normalize_case`` hook.


Unicode
-------

Lua is 8-bit clean and works great with Unicode inputs and dictionary files.
For best results, you should ensure your system locale is set appropriately,
usually to UTF-8 (otherwise Lua may have the wrong idea of
what constitutes an alphanumeric character, for instance).

However, tersen does not attempt to *normalize* Unicode,
which means that it may occasionally miss possible matches
if a dictionary source and the input tokens are written in different ways
(for instance, one uses combining characters and the other does not).
If this is a problem for your use case,
you should use another utility such as `uconv`_
to normalize your dictionary file and inputs prior to invoking tersen.

.. _uconv: https://unix.stackexchange.com/a/90164/


Dot-coalescing
--------------

If a replacement ends with ``.``
but a ``.`` already comes after the matched tokens in the source,
tersen will remove exactly one dot from the sequence;
this prevents sentences ending with ``..``
because the last word was substituted with a period-ending abbreviation.
(If the matched tokens had *more* than one dot after them
– for instance, if the sentence ended in an ellipsis –
only one of them will be removed.)


Performance
-----------

tersen is designed to be fast enough
that performance should not normally be a concern.
However, depending on what features you take advantage of,
what kind of speed you require,
and how much input you intend to pass to tersen,
you may want to consider a few things.

Building the lookup table is almost instantaneous in most cases,
even with annotations.
A 700-line tersen dictionary with liberal use of moderately complex annotations
and multiple sources takes under 10ms to build on my computer
(NB: my development machine is unusually fast for a desktop).
Thus, the main factor is usually how large your input is;
on the same machine and a large corpus,
tersen works at about 0.45 seconds per megabyte of input.
For comparison, a megabyte is about 180,000 words of English text,
so tersen processes about 400,000 words per second in this benchmark.

A significant secondary factor is the use of hooks, particularly ``no_match`` and ``normalize_case``.
Since these functions run against a large proportion of the words in the source text,
these are very "hot" functions
and almost anything you can do to speed them up
will likely have a noticeable impact if tersen is running slowly for you.
