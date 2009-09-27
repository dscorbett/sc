ABOUT SOUND CHANGER
Sound Changer (SC) is a Perl program by David Corbett released under GPLv3. It applies sound change rules to a list of words. The concept is based on SCA, a Python program by Geoff Eddy. SC addresses some of SCA's issues, like the banana problem and the limited categories and mapping system.

ENCODING
SC expects everything to be encoded in UTF-8. The command prompt can use any code page.

RUNNING SC
Type the following at the Windows command prompt: perl sc5.pl [arguments]

The arguments are optional. As a shorthand, only the capitalized letters must be typed, so -sep is equivalent to -separator.
-Cond=[conditions]: Those conditions, separated by commas, are now true.
-Dialects=[abc]: Only dialects a, b, and c will be displayed. If this argument is not set it displays all by default.
-Edit: Editing mode.
-Fields: Equivalent to -fields=1.
-Fields=[range]: The range is numbers with commas and dashes, like 1,3-5. SC will only look at the 1st, 3rd, 4th, and 5th fields separated by the field separator (by default, the comma).
-Help: Some basic help.
-HLevel=[number]: The highest comment level shown.
-HTML: HTML display mode.
-Limit=[number]: The maximum number of rules to apply per word, in case there is an infinite loop. The default is 1000.
-Mode=[number]: Sets verbosity mode.
-Nfkd: NFKD display mode.
-Output: Equivalent to -output=output_[rules file name].txt.
-Output=[filename]: Output will go to that file.
-Rules=[filename]: The rules file, including the filetype. The default is rules.txt.
-SEP: Sets the field separator to the tab character.
-SEParator=[string]: Sets the field separator. The default is the comma.
-Some: Only displays when a word has changed. The default is to show every rule.
-Unicode: Unicode display mode.
-eXact=[number]: Sets forgiveness level for a certain possible error.
-Words=[filename]: Whence to draw the words. The default is words.txt.

Anything else is treated as a word.

EDITING
Editing mode lets you retype the word after each rule. This is useful if a rule did not work as planned or if you wish to change a word in unpredictable ways (like jezo > zo in Geoff's Slavic romlang). Pressing Enter will keep the word as it is, and Ctrl+Z will exit editing mode for the rest of the rules for that word.

FIELDS
Normally, a words file is a list of words, one per line. But if there are multiple fields on a line (like the word and its translation) -fields can specify what to look for.

If the following is a line in a words file
foobar:masculine:object
you would type -f=1 -sep=: since "foobar" is the first field and they are separated by colons.

DISPLAY MODES
There are three display modes which take care of command prompt mojibake.
NFKD mode displays "é" as "e". It decomposes characters with NFKD and takes the base character. This does not work with combining diacritics.
HTML mode displays "é" as "&eacute;". There are 252 HTML code names, of which SC uses 246.
Unicode mode displays "é" as "{LATIN SMALL LETTER E WITH ACUTE}".

VERBOSTIY MODES
There are four verbosity modes:
0 displays the resulting word only.
1 displays the original and resulting words.
2 displays the word after each non-persistant rule (subject to -some).
3 displays the word after each rule (subject to -some).

OUTPUT
The word's evolution is displayed according to the mode under a heading for each dialect. In the following examples, A, B, and C are dialects, and text in brackets is a persistant rule.

Mode 3:
A:
foobar > fu:bar [ > fUbar] > fUba: [ > fUbA]
B:
foobar > fobar [ > fober] > f;ober > [ > f;ober] > fOber [ > fOber]
C:
foobar > fu:bar [ > fUbar > fUbbar]

Mode 2:
A:
foobar > fUbar > fUbA
B:
foobar > fober > f;ober > fOber
C:
foobar > fUbbar

Mode 1:
A:
foobar > fUbA
B:
foobar > fOber
C:
foobar > fUbbar

Mode 0:
A:
fUbA
B:
fOber
C:
fUbbar

The dialect headings don't appear when there are one or no dialects.

FORMAT OF THE RULES FILE
Each line is a comment, a directive, a definition, a rule, a category, or a blank line.

COMMENTS
Anything after an exclamation point is a comment. If a line begins with a hash it is a comment. If there some colons right after the hash, the line will be printed if the number of colons is no greater than the number after the -hlevel argument.

! This is a comment which will be ignored.
foo = b a r ! So is this.
# And this.
#: This will be printed with "-hl=1", "-hl=2", "=-hl=3", etc.
#:: Only "-hl=2", "-hl=3", etc. will show this.
foo = b a r # This is not a comment, and will generate an error message.

DIRECTIVES
Directives are SKIP, NOSKIP, and END. They are like multiline comment markers.

END means that nothing else in the file will be parsed.

Everything between SKIP and NOSKIP is skipped.

SKIP/NOSKIP IF/UNLESS COND will only work if/unless the condition is true.

DEFINITIONS
Definitions are (with optional bits in parentheses):
INCLUDE [filename]: immediately includes the file as if its contents were there in the main file.
COND(ITIONS) [string]: a list of conditions separated by commas that are set to true.
DIAL(ECTS) [string]: a list of all the dialects to be used in the file.
NAME [character] [string]: displays the character as the string; i.e. "NAME â a^".

CATEGORIES
Since examples are so useful, this is how to declare categories:
cat0 = abc def     ! cat0 = abc,def           (probably not what you wanted)
cat1 = a b c d e f ! cat1 = a,b,c,d,e,f
cat2 = <cat1> ghi  ! cat2 = a,b,c,d,e,f,g,h,i
cat3 = cat1        ! cat3 = c,a,t,1           (i.e. nothing special happens)
cat4 = . qu zxx #  ! cat4 = .,qu,zxx,#        (. matches anything and # is the word boundary symbol)

RULES
Finally! The rules! Before was just setting up; this is where everything happens.

A rule is written thus:
[DIALECTS] BEFORE > AFTER [FLAGS]

This means "For each of the DIALECTS, change BEFORE to AFTER, subject to the FLAGS."

DIALECTS is a string of letters or numbers specifying which dialects to apply the rule to. It must be written between brackets. Any character may be used as padding as long as it has not been previously defined as a dialect. Omitting the dialects means "all dialects".

BEFORE is a string of strings separated by whitespace, each of which may be:
A literal string;
A backreference;
A category reference.

A backreference is in the form $[number] and means "whatever was matched for part [number]". "<vowel> <cons> $1" means "a consonant between two of the same vowel".

Category references are very powerful. They are strings separated by +s and -s. Each of those pieces can be a category (<cat>) or a set of strings separated by pipes (a|b|c|d). Pieces not separated by a pipe represent any of the first followed by any of the second. The + strings are combined, and then anything in the - strings is taken out. Backreferences are allowed. Putting a caret at the beginning complements the whole thing.

Some examples, where cat = a,b,c and dog = d,e,f:
<cat>       = a,b,c
<cat>+x|y   = a,b,c,x,y
x|y+<cat>   = x,y,a,b,c
<cat>x      = ax,bx,cx
<cat><dog>  = ad,ae,af,bd,be,bf,cd,ce,cf
<cat>+<dog> = a,b,c,d,e,f
<cat><dog>  = a,b,c,d,e,f
<cat>-a|b   = c
<cat>-x|y   = a,b,c
^<cat>      = NOT a,b,c
^<cat>-a    = NOT b,c
v+w|x+y|z   = v,w,x,y,z
x-x         = ERROR
.|qu|zxx|#  = .,qu,zxx,#

AFTER is similar to BEFORE; each string may be:
A literal string;
A backreference;
A category reference with a backreference.

Backreferences here refer back to the BEFORE. Category references are the same as in BEFORE (but for complements) but they must have a backreference as a suffix. This is what SCA calls mapping. "<vowel> n > <nasvow>$1" means "the string in <nasvow> at the same index as $1 in <vowel>".

The first category must be no longer than the second category. If -exact=1, there is a warning if they are not the same length, and if -exact=2, the rule does not get accepted by the parser. This command line argument is provided because this feature can be useful, but it is also easy to do it by accident. It is up to the user to decide if it should be accepted or not.

The only FLAGS are P and R. P makes the rule persistent; it will be applied after each nonpersistent rule. R repeats the rule until it stops matching. It is NOT necessary to use R to solve the banana problem. That is taken care of automatically. Therefore, Welsh-style lenition works as expected:
unlen = p t k b d g
len   = b d g v D G
vowel = a e i o u
<vowel> <unlen> <vowel> > $1 <len>$2 $3

QUANTIFIERS
All of Perl's quantifiers work: *, +, ?, {}. ? for greed works too.

EXAMPLE RULES
Conversion:
<old> > <new>$1

Loss:
<cons>+ # > ! foobar > fooba

Conversion and loss:
<short> : > <long>$1 ! fo:bar > fObar

Metathesis:
<vowel> <liquid> > $2 $1 ! foobar > foobra

Epenthesis:
<nasal> <liquid> > $1 <vstop>$1 $2 ! nr > ndr, ml > mbl
#|<cons>|<long>|<vowel> <cons> <glide> <vowel> > $1 $2 <high>$3 $3 $4

Assimilation:
<nasal> <vstop> > <nasal>$2 $2 ! md > nd
<nasal> <vstop> > $2 $2 ! md > dd

Simplification:
<vowel> $1 > $1 ! foobar > fobar
<vowel> $1 > $2 ! foobar > fobar

Gemination:
<vowel> <cons> <vowel> > $1 $2 $2 $3 ! foobar > foobbar

Spellings:
c|q|L|N|R|x|S|Z > ty|dy|ly|ny|ry|kh|sh|zh$1 ! Liotan respelling

COMPARISON BETWEEN SC AND SCA
SCA                 | SC
Python              | Perl
syntax highlighting | 
CSV output          | plain output
conciseness         | whitespace
environment fields  | 
                    | no banana problem
                    | run-time editing
                    | multiple display styles
categories and maps | better categories and maps

CREDITS
I wrote SC all by myself. However, Geoff Eddy's program was a source of great inspiration for me. His documentation was also a great source of inspiration for this document, so that it is best to read his alongside mine.

LINKS
Geoff Eddy's SCA   http://www.cix.co.uk/~morven/lang/sc.html
sounds             http://www.zompist.com/sounds.htm