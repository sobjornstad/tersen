Hooks
=====

Tersen is intended to have sane default behavior for most use cases,
but there are a wide variety
of languages and abbreviation systems in the world,
so its default behavior may not be suitable for all of them.
To add some flexibility, tersen has various *hooks* scattered throughout its codebase.

By uncommenting a hook and giving it an implementation in ``hooks.lua``,
you can change the behavior of a small piece of tersen's process.
For instance, you might want to change
what happens if a source :ref:`is defined twice in the dictionary <Basics>`,
or :ref:`how the case of replacements is determined <Case>`.
The names of hooks that can be used to customize behavior
are mentioned throughout this manual.
If you find there is no hook present for an aspect of behavior you need to change,
pull requests adding such a hook are welcome.

To get started, grab a copy of the ``hooks.lua``,
which has commented-out stub implementations and extensive comments
on all the available hooks.
When you run tersen, supply the ``-h hookfile`` argument.
If you don't want to type this every time you run tersen,
:ref:`set up <tersenrc>` a ``.tersenrc``.

.. todo:: GitHub link