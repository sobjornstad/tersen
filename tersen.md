# Tersen

**Tersen** is an abbreviation engine
    that compresses text in a human-readable fashion.

Use cases include:

* Packing more information onto a cheat sheet or reference guide.
* Sending content over SMS or another limited-bandwidth communication channel.
* Obfuscating content so others cannot easily read it but you can.
* Practicing your reading skills in your favorite alphabetic shorthand system.

Tersen is written in Lua. It is fast, flexible, and small.


## Mappings

To tell tersen how you want to abbreviate things,
    you create a tersen dictionary which contains one or more *mappings*.
A mapping consists of one or more source tokens (e.g., `Internet`)
    and a destination string (e.g., `I.N.`).
When tersen encounters the source token(s) in its input,
    it will replace them with the destination string in its output.

### Tokens and sources

Tokens are strings consisting of alphanumeric characters, `-`, or `'`.
Tokens are separated by whitespace.
Other characters, such as punctuation,
    may be at the beginning or end of the token;
    when found in the input, these are ignored for matching purposes,
    but are preserved in the output
    (e.g., with the mapping presented above,
     if `Internet,` was found in the source,
     `I.N.,` would appear in the destination).

A source may consist of more than one token.
When tersen encounters an input token
    that could match the source of multiple mappings,
    it looks ahead and picks the longest possible match.
For instance,
    if your dictionary contains both `Internet` and `Internet Protocol`,
    the phrase `the Internet is` becomes `the I.N. is`,
    while `Internet Protocol` becomes `IP` (not `I.N. Protocol`).
The “longest possible match” is the one with the most tokens;
    it is not necessarily the way of dividing tokens
    that produces the shortest output.
(tersen is *greedy*;
    it will never backtrack over a replacement it has already made,
    even if another division of tokens could produce a shorter output.
 While that gives up a small amount of possible compression,
    it keeps tersen fast and simple
    and makes replacement behavior more predictable.)

!!! TODO: Define “inner token” and “outer token”

A source cannot contain punctuation other than hyphens or apostrophes (curly or straight),
    so you cannot have a source of `#&$%` or `St. Paul`.
If such a source is found,
    a warning will be printed and that mapping will be ignored.
*However*, you can sometimes get around this;
    if a multi-word phrase matches input
    when ignoring the punctuation in the input,
    the replacement will still be made
    and any medial punctuation will disappear.
For instance, if you have a mapping from `St Olaf` to `STO`,
    and the text `St. Olaf` is found in the input,
    it will be replaced with `STO`.
One could imagine a case where this would do the wrong thing,
    such as “222 Somewhere St., Olaf City, CA”,
    but in general this is unlikely
    (and it will always be possible to fool tersen in some edge cases!).

Only one mapping may be present in the dictionary for each `source`.
If the same source is mapped more than once,
    the first entry wins,
    and tersen will print a warning.


### Destinations

A destination may be any string,
    except one that contains the at-sign (`@`)
    or has leading or trailing whitespace
    (tersen ignores whitespace when matching and replacing,
     but preserves it as best as possible in its output).

If a destination is longer than its corresponding source,
    tersen will print a warning but still use the mapping.


## The tersen dictionary

The abbreviation table is defined in a *tersen dictionary*,
    a text file with the following format.

Lines beginning with the comment character `#` and blank lines are ignored.
All other lines create one or more mappings.
The ordering of entries in the dictionary does not matter,
    unless you accidentally map the same source to multiple destinations,
    in which case the first one wins.

The simplest kind of dictionary line looks like this:

    source => destination

This creates a mapping that will replace `source` with `destination` in output.

Oftentimes you want to map several sources to the same destination.
You can do this by separating them with commas:

    source1, source2 => destination

You can also apply *annotations* to any dictionary line.
Annotations are Lua functions
    that transform the source and destination in an arbitrary way.
An annotation can output one mapping or many mappings;
    for instance, you might wish to add both the singular form
    and a plural form of a word using an annotation.
Several annotations are provided with tersen,
    and you can easily write your own.

The following section documents the built-in annotations,
    which are geared towards Dutton Speedwords;
    you can customize the annotation functions
    for whatever source language and abbreviation language you’re using,
    and even add your own.
An annotation looks like this:

    tree => bo @n

`@` indicates the end of the destination part
    and the beginning of the annotation part.
The `n` annotation indicates that this is a noun
    and a plural form should be entered as well;
    when tersen reads this dictionary line,
    it creates a mapping `tree => bo`
    as well as a mapping `trees => boz`,
    `z` being the plural suffix in Speedwords.

If the plural form doesn’t consist of the word plus an *s*,
    you can specify one or more *arguments* to the annotation.
For the built-in noun form, there is only one argument, the plural form:

    leaf => fol @n[leaves]

Similar annotations are available for adjectives and verbs:

    easy => fas @adj[easier easiest]

Which creates `easy => fas`, `easier => mefas`, and `easiest => myfas`.
For verbs:

    walk => gog @v[walks walked walked walking]

The arguments here are
    the third-person form,
    the simple past,
    the perfect,
    and the present participle.
This creates `walk => gog`, `walks => gog`, `walked => gogd`, and `walking => ugog`.
Note that the past and the perfect, `walked` are the same;
    we don’t get a warning when this happens on an annotation,
    the perfect simply wins as a replacement.

As you can see, arguments are typically placed in square brackets
    and separated by spaces.
If the arguments need to be multiple words,
    you can use an alternate form where each argument
    is in its own set of curly braces:

    log in => lgn @v{logs in}{logged in}{logged in}{logging in}

Annotation arguments can contain any non-newline character except
    whitespace and closing square brackets (in the square-bracketed form)
    or closing curly braces (in the curly-braced form).


## Case

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
  its tersened output will have its first character capitalized.
  (TODO: Would be nice to make this proper title case.)
* Otherwise, the output will be whatever case the replacement is.

Though these rules are not always perfect,
    for the most part, tersen will just “do the right thing” with case.


## Special cases

If a replacement ends with `.`
    but a `.` already comes after the matched tokens in the source,
    tersen will remove one dot;
    this prevents sentences ending with `..`
    because the last word was substituted with a period-ending abbreviation.
(If the matched tokens had *more* than one dot after them
    – for instance, if the sentence ended in an ellipsis –
    only one of them will be removed.)


## Writing annotation functions

Annotations are Lua functions in the `M` table in the `annot.lua` file.
The name of the function
    is the name used to access the annotation in the tersen dictionary,
    and may contain letters, numbers, and underscores
    (but may not begin with a digit).
The function takes three arguments:
    the source listed in the tersen dictionary,
    the destination listed in the tersen dictionary,
    and a list of arguments to the annotation (or nil if there were no arguments).
It returns a table of mappings,
    the keys being sources and the values being destinations.

If there are multiple comma-separated sources,
    the annotation function is called separately for each source.

Here’s a simple example, the function backing `@apos`,
    which ensures that any apostrophes in the source value
    get dictionary entries for both curly apostrophes and straight apostrophes.

    function M.apos (source, dest, args)
        local straight = string.gsub(source, "'", "’")
        local curly = string.gsub(source, "’", "'")
        return {[straight] = dest, [curly] = dest}
    end


## Flags

The following characters of punctuation, called *flags*,
    when placed before the first non-punctuation character on a line,
    have special effects.
Any number of flags can be used together,
    and if the same flag is used twice,
    tersen will behave as if it were used only once.

* `!` – The *cut* flag causes tersen to
  stop parsing the dictionary immediately after this entry.
  This may be useful if you’re trying to debug a small portion of the dictionary.
  To reduce the risk of accidentally leaving a cut in the dictionary file,
      a warning will be printed anytime a cut is present,
      indicating which line the cut is on.

* `?` – The *trace* flag causes tersen to
  print its internal lookup-table structure
  for all entries generated by this dictionary line.
  This can be useful when debugging annotations.
  For multi-word tokens, the structure will be printed back from the first token
  (so if “Internet Protocol” has a ? by it,
   the entry for “Internet” will appear,
   containing “Internet Protocol” as a continuation member).
  Note that the trace is printed for *all* items with a `?`
  after the entire dictionary is read;
  if you think a later entry is conflicting with an earlier one
  and you want to see only the table that would be generated by this single line,
  you should move it to the top of the file
  and apply a cut (`!`) to it as well as a trace.

  A warning is printed anytime a trace is present.

* `-` – The *suppress redefinition* flag silences any warnings
  that would otherwise be displayed if any mappings created by this line
  conflict with existing mappings.
  This only affects the display of the warning;
  the original mappings will win, as they would without the flag.
  This flag is useful when using an annotation that happens to generate
  an item with the same source as a previous mapping;
  for instance, the present tense of the verb `lead`
  and the singular form of the noun `lead` are identical,
  but you might want to include their base forms
  and attach noun and verb annotations to them in the dictionary
