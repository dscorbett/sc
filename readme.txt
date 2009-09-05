==About Sound Changer==
Sound Changer (SC) is a Perl program which applies sound change rules to a list of words. The concept is based on SCA, a Python program by Geoff Eddy. Unfortunately, when I tried to run it it would not work, so I wrote my own version. SC addresses some of SCA's issues, like the banana problem and the unintuitive (for me, anyway) mapping system.

==Running SC==
Type the following at the command prompt: perl sc4.1.pl [arguments]
All arguments are optional and can take just the first letter as a shorthand. They are as follows:
-cond=[condition]: That condition is now true.
-dialects=[abc]: Only dialects a, b, and c will be displayed. If this argument is not set it displays all by default.
-edit: Turns on editing mode.
-fields=[range]: The range is numbers with commas and dashes, like 1,3-5. SC will only look at the 1st, 3rd, 4th, and 5th fields separated by the field separator (by default, the comma).
-hlevel=[number]: The highest comment level shown.
-limit=[number]: The maximum number of rules to apply per word, in case there is an infinite loop. The default is 1000.
-mode=[number]: See below.
-notall: Only displays when a word has changed; the default is to show every rule.
-output=[filename]: Output will go to that file. If you only type -o it will default to output.txt.
-rules=[filename]: The rules file, including the filetype. The default is rules.txt.
-separator=[string]: The field separator. The default is the comma.
-words=[filename]: Whence to draw the words. The default is words.txt.
Anything else is treated as a word and is processed before the input words file (if there is one).

==Editing==
Editing mode lets you retype the word after each rule. This is useful if a rule did not work as planned or if you wish to change a word in unpredictable ways (like jezo > zo in Geoff's Slavic romlang). Pressing Enter will keep the word as it is, and Ctrl+Z will exit from editing for the rest of the rules for that word. Anyway, it was fun to add in.

==Modes==
There are four modes:
0: displays the resulting word only
1: displays the original and resulting words
2: displays the word after each non-persistant rule (subject to -some)
3: displays the word after each rule (subject to -some)

==Output==
The word's evolution is displayed according to the mode under a heading for each dialect. An example in mode 3:
A:
foobar > fu:bar [ > fUbar] > fUba: [ > fUbA]
B:
foobar > fobar [ > fober] > f;ober > [ > f;ober] > fOber [ > fOber]
C:
foobar > fu:bar [ > fUbar > fUbbar]

In mode 2:
A:
foobar > fUbar > fUbA
B:
foobar > fober > f;ober > fOber
C:
foobar > fUbbar

In mode 1:
A:
foobar > fUbA
B:
foobar > fOber
C:
foobar > fUbbar

In mode 0:
A:
fUbA
B:
fOber
C:
fUbbar

The dialect headings don't appear when there are one or no dialects.

==Format of the rules file==
Each line is a comment, a directive, a definition, a rule, a category, or a blank line.

Anything after an exclamation point is a comment. If a line begins with a hash it is a comment. If there some colons right after the hash, the line will be printed if the number of colons is no greater than the number after the -hlevel argument.

! This is a comment which will be ignored.
foo = b a r ! So is this.
# And this.
#: This will be printed with "-h=1".
#:: This won't, but "-h=2" will show it.
foo = b a r # This is not a comment, and will generate an error message.

Directives are SKIP, NOSKIP, and END. They are like multiline comment markers.
END means that nothing else in the file will be parsed.
Everything between SKIP and NOSKIP is skipped.
SKIP/NOSKIP IF/UNLESS COND will only work if/unless the condition is true.

Definitions are (with optional bits in parentheses):
DIAL(ECTS) [string]
COND(ITIONS) [string]
INCLUDE [filename]

Dialects is a list of all the dialects to be used in the file.
Conditions is a list of conditions separated by commas that are set to true.
Including a file immediately includes it as if it were part of the original file.

Since examples are so useful, this is how to declare categories:
cat0 = abc def     ! cat0 = abc,def         (probably not what you wanted)
cat1 = a b c d e f ! cat1 = a,b,c,d,e,f
cat2 = <cat1> ghi  ! cat2 = a,b,c,d,e,f,g,h,i
cat3 = cat1        ! cat3 = c,a,t,1         (i.e. nothing special happens)
cat4 = sh qu zxx # ! cat4 = sh,qu,zxx,#     (# is the word boundary symbol)

==Rules==
Wow! The rules! Before was just setting up; this is where everything happens.

A rule is written thus:
[DIALECTS] BEFORE > AFTER [FLAGS]

This means "For each of the DIALECTS, change BEFORE to AFTER, subject to the FLAGS."

DIALECTS is a string of letters or numbers specifying which dialects to apply the rule to. It must be written between brackets. Any character may be used as padding as long as it has not been previously defined as a dialect. Omitting the dialects means "all dialects".

BEFORE is a string of strings separated by whitespace, each of which may be:
A literal string;
A backreference;
A category reference.

A backreference is in the form $[number] and means "whatever was matched for part [number]". "<vowel> <cons> $1" means "a consonant between two of the same vowel".

Category references are very powerful. They are strings separated by +s and -s. Each of those pieces can be a category (<cat>) or a set of strings separated by pipes (a|b|c|d). The + strings are combined, and then anything in the - strings is taken out. Backreferences are allowed. Putting a caret at the beginning complements the whole thing.

Some examples, where cat = a,b,c and dog = d,e,f:
<cat>       = a,b,c
<cat>+x|y   = a,b,c,x,y
x|y+<cat>   = x,y,a,b,c
<cat>+a     = a,b,c,a
<cat>+<dog> = a,b,c,d,e,f
<cat><dog>  = a,b,c,d,e,f
<cat>-a|b   = c
<cat>-x|y   = a,b,c
^<cat>      = NOT a,b,c
^<cat>-a    = NOT b,c
v+w|x+y|z   = v,w,x,y,z
x-x         = ERROR
sh|qu|zxx   = sh,qu,zxx

AFTER is similar to BEFORE; each string may be:
A literal string;
A backreference;
A category reference with a backreference.

Backreferences here refer back to the BEFORE. Category references are the same as in BEFORE (but for complements) but they must have a backreference as a suffix. This is what SCA calls mapping. "<vowel> n > <nasvow>$1" means "the string in <nasvow> at the same index as $1 in <vowel>". The two categories must have the same length.

The FLAGS are P and R. P makes the rule persistent; it will be applied after each nonpersistent rule. R repeats the rule until it stops matching. It is NOT necessary to use R to solve the banana problem. That is taken care of automatically. Therefore, Welsh-style lenition works as expected:
unlen = p t k b d g
len   = b d g v D G
vowel = a e i o u
<vowel> <unlen> <vowel> > $1 <len>$2 $3

==Quantifiers==
All of Perl's quantifiers work: *, +, ?, {}. ? for greed works too.

==Example rules==
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

==Differences from SCA==
Bad:
SC does not have syntax highlighting and does not support Unicode. I think that last is a problem with Perl and the Windows command prompt, but if you output to a file with the same encoding as the input words file, the Unicode will work. I pretty sure anyway. Also, SC has no separators for output files like OpenOffice.

In addition SC is very wordy. It has a lot of whitespace (necessary for supporting multicharacter strings in characters). It also uses a lot of backreferences for some kinds of rules, like Sievers's law up in the examples.

Good:
It's nice to end on a positive note, isn't it? SC's categories are much more versatile because you can string together as many elements as you want to easily make one-time-use categories. It also has run-time editing, for what that's worth.

This I am most proud of: SC solves the banana problem automatically. This was a big part of the reason I wrote my own program. It does it by looping through and seeing if there are any matches starting at each possible index. It might be inefficient but it is guaranteed to never miss a match.

==Credits==
I wrote SC all by myself. However, Geoff Eddy's program was a source of great inspiration for me. His documentation was also a great source of inspiration for this document, so that it is best to read his alongside mine.