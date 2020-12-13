Command-line options
====================

You can find a full accounting of tersen's command-line options by running
``tersen --help``.

tersenrc
--------

On startup, tersen looks for a file called ``.tersenrc`` in your home directory.
If found, each line in the file will be treated
as if it was passed as a command-line argument to tersen,
with all arguments in the ``.tersenrc``
coming before any that you actually type on the command line.

If you don't want to use the options in your ``.tersenrc`` for a given run,
pass the ``--no-rcfile`` option.
