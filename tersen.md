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

A source cannot contain punctuation other than hyphens or apostrophes,
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

You can also use *annotations*
    to automatically generate several sources and destinations
    when several can be inferred based on a single mapping.
The following section documents the built-in annotation format,
    which is geared towards Dutton Speedwords;
    you can customize the annotation functions
    for whatever source language and abbreviation language you’re using,
    and even add your own.

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
    you can specify one or more space-separated *arguments* to the annotation.
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
