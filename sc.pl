#!/bin/perl
# based on 3.4.pl, with:
# quantifiers
# recognition of digraphs as single units
# word boundaries
# word boundaries in categories
# deletions
# complements
# greed, except for the first string because of the banana solution
# consolidated condition input
# optional limits
# editing set per word, not per set of all words

# TODO:
# comment levels
# Unicode support
# merging of redundant code
# reorganization of code
# reorganization of escaped Perl regex characters
# presentation
# documentation

use feature "say";
use strict;
use warnings;

######## COMMAND-LINE ARGUMENTS ########

my $rules = "rules.txt";
my $words;
my @words;
my $output;
my $limit = my $maxLimit = 1000; 
my $mode = 3; # 0 = results only; 1 = superbrief; 2 = brief; 3 = verbose
my @clWords;
my %cond;
my $edit = 0;

foreach (@ARGV) {
  (/^-(?:r|rules)=(.+)$/i) ? $rules = $1 :
  (/^-(?:w|words)=(.+)$/) ? $words = $1 :
  (/^-(?:o|output)=(.+)$/i) ? $output = $1 :
  (/^-(?:l|limit)=(\d+)$/i) ? $limit = $maxLimit = $1 :
  (/^-(?:m|mode)=(\d+)$/i) ? $mode = $1 :
  (/^-(?:c|cond)=(.+)$/i) ? parseCond (uc $1) :
  (/^-(?:e|edit)$/i) ? $edit = 1 :
  push @clWords, $_;
}

if ($limit == 0) {
  $limit = $maxLimit = .5;
}

if (defined $output) {
  open OUTPUT, ">$output" or warn "$output not accessible\n";
  $output = *OUTPUT;
}

$words = "words.txt" unless (defined $words || $#clWords > -1);
if (defined $words) {
  open WORDS, "<$words" or die "$words not found\n";
  chomp(@words = <WORDS>);
  close WORDS;
}
push @words, @clWords;

######## VARIABLES ########

my %cats;
my @tentAvant;
my @scAvant;
my @scApres;
my @absMap;
my @map;
my $scNum = 0;
my $dialect = "";
my @scLects;
my @scPersist;
my @scRepeat;
my @scPersistRepeat;
my $skip = 0; # 0 = noskip; 1 = skip

######## RULES ########

open RULES, "<$rules" or die "$rules not found\n";
RULE: while (<RULES>) {
  # SET-UP
  next if (/^\s*($|!)/); # comment or blank line
  chomp;
  ($_) = split /!/, $_;
  $_ = trim ($_);
  
  # SKIPPING AND ENDING
  my $skipping = 0;
  if (/^(SKIP|NOSKIP|END)\b/i) {
    if (/^SKIP\b/i) {
      if (/^SKIP\s+(IF|UNLESS)\s+(.+)/i) {
        next RULE if (uc $1 eq "IF" && !exists $cond{uc $2});
        next RULE if (uc $1 eq "UNLESS" && exists $cond{uc $2});
      }
      $skip = 1;
    } elsif (/^NOSKIP\b/i) {
      if (/^NOSKIP\s+(IF|UNLESS)\s+(.+)/i) {
        next RULE if (uc $1 eq "IF" && !exists $cond{uc $2});
        next RULE if (uc $1 eq "UNLESS" && exists $cond{uc $2});
      }
      $skip = 0;
    } elsif (/^END\b/i) {
      if (/^END\s+(IF|UNLESS)\s+(.+)/i) {
        next RULE if (uc $1 eq "IF" && !exists $cond{uc $2});
        next RULE if (uc $1 eq "UNLESS" && exists $cond{uc $2});
      }
      last RULE;
    }
    $skipping = 1;
  }
  next if ($skip);
  
  if (/^\[(.*)\]$/) {
    $dialect .= $1;
  } elsif (/ > /) {
    my @rule = split / > /;
    @tentAvant = ();
    
    if (defined $rule[0]) {
      my @avant = split (/\s+/, $rule[0]);
      if ($avant[0] =~ /\[(.*)\]/) {
        push @scLects, $1;
        shift @avant;
      }
      
      my @tmpAvant = parseAvant (@avant);
      next RULE if ($#tmpAvant == -1);
      push @tentAvant, $scNum, @tmpAvant;
      
      my @apres = (""); # so it won't complain if there is no apres (i.e. a deletion)
      @apres = split (/\s+/, $rule[1]) if defined $rule[1];
      if ($apres[-1] =~ /\[(.*)\]/) {
        my $flags = $1;
        if ($flags =~ /P/i) {
          push @scPersist, $scNum;
          if ($flags =~ /R/i) {
            push @scPersistRepeat, $scNum;
          }
        } elsif ($flags =~ /R/i) {
          push @scRepeat, $scNum;
        }
        pop @apres;
      }
      
      my @tentAvantPart = tentAvantCat ($scNum);
      my @tmpApres = parseApres (($#tentAvantPart + 1) / 2, $scNum, @apres);
      next RULE if ($#tmpApres == -1);
      
      push @scAvant, @tentAvant;
      push @scApres, $scNum, @tmpApres;
      
      $scNum++;
    } else {
      warn "Rule ", $scNum + 1, " has no original form\n";
    }
  } elsif (/=/) {
    (my $cat, my $contents) = split /=/, $_, 2;
    $cat = trim ($cat);
    $contents = trim ($contents);
    parseCat ($cat, $contents);
  } else {
    warn "Unparsable statement \"$_\" ignored\n" unless ($skipping);
  }
  warn "Ambiguous statement \"$_\" parsed as a sound change\n" if (/=/ && / > /);
}
close RULES;

#say "av: ", join ",", @scAvant;
#say "ap: ", join ",", @scApres;
#foreach my $name (keys %cats) {
#  print "$name: ";
#  foreach (0 .. $#{$cats{$name}}) {
#    print "@{$cats{$name}}[$_],";
#  }
#  say "";
#}
#say "p:  ", join ",", @scPersist;
#say "r:  ", join ",", @scRepeat;
#say "pr: ", join ",", @scPersistRepeat;

######## WORDS ########

$dialect = " " if ($dialect eq "");
foreach my $dial (split //, $dialect) {
  record ("$dial:\n") if (length $dialect > 1);
  foreach (@words) {
    $limit = $maxLimit;
    $edit = 1 if ($edit == -1);
    chomp;
    my $word = $_;
    record ($word) unless ($mode == 0);
    my @index;
    SC: for (my $i = 0; $i < $scNum; $i++) {
      my $old = $word;
      next SC unless ($dialect eq " " || !defined ($scLects[$i]) || $scLects[$i] =~ /$dial/);
      next SC if (join (",", @scPersist) =~ /$i/);
      @index = regindex ($word, $i);
      my $offset = 0;
      while (@index > 0) {
        my $avant = join "", avantCat ($i);
        my $apres = join "", apresCat ($i);
        ($word, $offset) = replace ($i, $word, $offset, shift @index, shift @index, $avant, $apres);
        my $mapShift = shift @map;
        shift @map foreach (1 .. $mapShift);
      }
      $word = edit (" > ", $word) if ($mode >= 3);
      $limit--;
      die "\nQuitting due to possible infinite repetition\n" if ($limit == 0);
      
      record (" [") if ($#scPersist > -1 && $mode >= 3);
      PSC: for (my $j = 0; $j < $scNum; $j++) { # $j < $#scAvant
        my $oldP = $word;
        next PSC unless ($dialect eq " " || !defined ($scLects[$j]) || $scLects[$j] =~ /$dial/);
        next PSC unless (join (",", @scPersist) =~ /$j/);
        @index = regindex ($word, $j); # ($word, $scAvant[$j], $j)
        my $offset = 0;
        while (@index > 0) {
          my $avant = join "", avantCat ($j);
          my $apres = join "", apresCat ($j);
          ($word, $offset) = replace ($j, $word, $offset, shift @index, shift @index, $avant, $apres);
          my $mapShift = shift @map;
          shift @map foreach (1 .. $mapShift);
        }
        $word = edit (" > ", $word) if ($mode >= 3);
        $limit--;
        die "\nQuitting due to possible infinite repetition\n" if ($limit == 0);
        $j-- if (join (",", @scPersistRepeat) =~ /$j/ && $word ne $oldP);
      }
      record ("]") if ($#scPersist > -1 && $mode >= 3);
      
      $word = edit (" > ", $word) if ($mode == 2);
      $i-- if (join (",", @scRepeat) =~ /$i/ && $word ne $old);
    }
    $word = edit (" > ", $word) if ($mode == 1);
    record ($word) if ($mode == 0);
    record ("\n");
  }
}

######## PARSING SUBROUTINES ########

sub parseAvant {
  my @ret;
  foreach (@_) {
     # COMPLEMENTS
     my $complement = "";
     my $complement2 = "";
     $complement = "(?!" if (/^\^/);
     $complement2 = ")." if (/^\^/);
     $_ =~ s/^\^//;
    
    # QUANTIFIERS AND GREED
    my $min = 1;
    my $max = 1;
    my $greed = "";
    if (/\*(\?|)$/) {
      $min = 0;
      $max = "";
      $greed = "?" if ($1 eq "?");
    } elsif (/\+(\?|)$/) {
      $min = 1;
      $max = "";
      $greed = "?" if ($1 eq "?");
    } elsif (/\{(.*)\}(\?|)$/) {
      $greed = "?" if ($2 eq "?");
      if ($1 =~ /(\d+),(\d+)/) {
        $min = $1;
        $max = $2;
      } elsif ($1 =~ /(\d+),/) {
        $min = $1;
        $max = "";
      } elsif ($1 =~ /,(\d+)/) {
        $min = 0;
        $max = $1;
      } elsif ($1 =~ /(\d+)/) {
        $min = $1;
        $max = $1;
      }
    } elsif (/\?(\?|)$/) {
      $min = 0;
      $max = 1;
      $greed = "?" if ($1 eq "?");
    }
    if ($max ne "" && $min > $max) {
      my $tmp = $min;
      $min = $max;
      $max = $tmp;
    }
    $_ =~ s/(\{(.*)\}|\*|\+|\?)(\?|)$//;
    
    # THE MAIN PART OF THE REGEX
    my $part;
    $_ =~ s/>(?!\+|-|\|)(?=.+)/>+/; # put a + between > and any non-(+-|)
    $_ =~ s/(?!\+|-|\|)(?=.+)</+</; # put a + between any non-(+-|) and <
    $_ =~ s/>\|</>+</g; # change | to + between categories
    $_ =~ s/#/\\b/g; # change # to \b
    
    my @pieces = split /(?=\+|^|-)/, $_;
    
    foreach my $piece (@pieces) {
      next if ($piece =~ /^-/);
      $piece =~ s/\+//;
      if ($piece =~ /^<(.*)>$/) {
        my $contents = catContents ($1);
        return ("", -1) if ($contents eq "");
        $part .= "|" . $contents;
      } else {
        $part .= "|" . $piece;
      }
    }
    my @minus;
    foreach my $piece (@pieces) {
      next unless ($piece =~ /^-/);
      $piece =~ s/-//;
      my @mPieces = split /\|/, $piece;
      foreach my $mPiece (@mPieces) {
        if ($mPiece =~ /^<(.*)>$/) {
          my $contents = catContents ($1);
          return if ($contents eq "");
          push @minus, split /\|/, $contents;
        } else {
          push @minus, $mPiece;
        }
      }
    }
    foreach my $del (@minus) {
      $part =~ s/\|$del(?=\||$)//g;
    }
    if (!defined $part || $part eq "") {
      warn "Useless empty string in the first half of rule ", $scNum + 1, "\n";
      return;
    }
    $part =~ s/^\|//;
    $part =~ s/\|$//;
    
    push @ret, "($complement$part$complement2)", "{$min,$max}$greed";
  }
  return @ret;
}

sub parseApres {
  my $total = shift;
  my $scNum = shift;
  my @ret;
  my $counter;
  my $mapCounter;
  return "" if ($_[0] eq ""); # TODO: special case for deletions
  foreach (@_) {
    $counter++;
    
    # BACKREFERENCE
    my $suffix;
    if (/\$0*(\d+)$/) {
      $suffix = $1;
    } else {
      $suffix = -1;
    }
    $_ =~ s/\$0*(\d+)$//;
    if ($suffix eq "0" || $suffix > $total) {
      warn "Invalid backreference \$$suffix for <$_> in rule ", $scNum + 1, "\n";
      return;
    }
    
    # THE MAIN PART OF THE REGEX
    my $part;
    $_ =~ s/>(?!\+|-|\|)(?=.+)/>+/g; # put a + between > and any non-(+-|)
    $_ =~ s/(?!\+|-|\|)(?=.+)</+</; # put a + between any non-(+-|) and <
    $_ =~ s/>\|</>+</g; # change | to + between categories
    
    my @pieces = split /(?=\+|^|-)/, $_;
    
    unless ($#pieces == -1) {
      foreach my $piece (@pieces) {
        next if ($piece =~ /^-/);
        $piece =~ s/\+//;
        if ($piece =~ /^<(.*)>$/) {
          my $contents = catContents ($1);
          return if ($contents eq "");
          $part .= "|" . $contents;
        } else {
          $part .= "|" . $piece;
        }
      }
      my @minus;
      foreach my $piece (@pieces) {
        next unless ($piece =~ /-/);
        $piece =~ s/^-//;
        my @mPieces = split /\|/, $piece;
        foreach my $mPiece (@mPieces) {
          if ($mPiece =~ /^<(.*)>$/) {
            my $contents = catContents ($1);
            return ("", 0) if ($contents eq "");
            push @minus, split /\|/, $contents;
          } else {
            push @minus, $mPiece;
          }
        }
      }
      foreach my $del (@minus) {
        $part =~ s/\|$del(?=\||$)//g;
      }
      if (!defined $part || $part eq "") {
        warn "Useless empty string in the second half of rule ", $scNum + 1, "\n";
        return;
      }
      $part =~ s/^\|//;
    } else {
      $part = avantCatContents ($scNum, $suffix);
    }
    
    # In the following, defined $part is for when there is a deletion (i.e. no apres)
    if (defined $part && $suffix == -1 && ($part =~ tr/\|//) != 0) {
      warn "Unspecified backreference for <$part> in rule ", $scNum + 1, "\n";
      return;
    }
    #if ($suffix eq "0" || $suffix > $total) {
    #  warn "Invalid backreference: \$$suffix in rule ", $scNum + 1, "\n";
    #  return;
    #}
    if (defined $part && ($part =~ tr/\|//) != avantCatLength ($scNum, $suffix)) {
      my $x = ($part =~ tr/\|//);
      warn "Category length mismatch with <$part>\$$suffix (" . (avantCatLength ($scNum, $suffix) + 1) . " != ", $x + 1 . ") in rule ", $scNum + 1, "\n";
      return;
    }
    unless ($suffix == -1) {
      $mapCounter++;
      push @ret, "\$map[$mapCounter]";
      push @absMap, $scNum, $suffix, avantCatContents ($scNum, $suffix), $part; # explanation of @absMap
    } elsif (defined $part) {
      push @ret, $part;
    }
  }
  return @ret;
}

sub parseCat {
  my $cat = shift;
  warn "Overwriting <$cat>\n" if (exists $cats{$cat});
  if($cat =~ /(\s|\+|-)/) {
    warn "Illegal character in <$cat>'s name: \"$1\"\n";
    return;
  }
  my $contents = shift;
  my @contents = split /\s+/, $contents;
  my $tmp = [];
  
  foreach (@contents) {
    my $part;
    $_ =~ s/>(?!\+|-|\|)(?=.+)/>+/g; # put a + between > and any non-(+-|)
    $_ =~ s/(?!\+|-|\|)(?=.+)</+</; # put a + between any non-(+-|) and <
    $_ =~ s/>\|</>+</g; # change | to + between categories
    $_ =~ s/#/\\b/g; # change # to \b
    
   # $_ =~ s/(\\|\$|\^|\*|\?|\.|\(|\))/\\$1/;
    my @pieces = split /(?=\+|^|-)/, $_;
    
    foreach my $piece (@pieces) {
      next if ($piece =~ /^-/);
      $piece =~ s/\+//;
      if ($piece =~ /^<(.*)>$/) {
        my $contents = catContents ($1);
        return if ($contents eq "");
        $part .= "|" . $contents;
      } else {
        $part .= "|" . $piece;
      }
    }
    my @minus;
    foreach my $piece (@pieces) {
      next unless ($piece =~ /-/);
      $piece =~ s/^-//;
      my @mPieces = split /\|/, $piece;
      foreach my $mPiece (@mPieces) {
        if ($mPiece =~ /^<(.*)>$/) {
          my $contents = catContents ($1);
          return ("", -1) if ($contents eq "");
          push @minus, split /\|/, $contents;
        } else {
          push @minus, $mPiece;
        }
      }
    }
    foreach my $del (@minus) {
      $part =~ s/\|$del//g;
    }
    
    $part =~ s/^\|//;
    push @$tmp, split /\|/, $part;
  }
  if ($#$tmp == -1) {
    warn "Useless empty category <$cat>\n";
    return;
  }
  $cats{$cat} = $tmp;
}

sub parseCond {
  $cond{$_} = "" foreach (split ",", shift);
}

######## SOUND-CHANGING SUBROUTINES ########

sub regindex {
  my $word = shift;
  my $scNum = shift;
  my $regex; # = join "", avantCat ($scNum);
  my @avant = avantCat ($scNum);
  foreach (0 .. $#avant) {
    if ($_ % 2 == 0) {
      $regex .= "($avant[$_]";
    } else {
      $regex .= "$avant[$_])";
    }
  }
  
  my @ret;
  my @ref = ();
  my $greatestIndex = 0;
  for (my $i = 0; $i < length $word; $i++) {
    die "\nQuitting due to overly long word\n" if ($i > 32766);
    if ($word =~ /(?:^.{$i})$regex/) {
      if ($greatestIndex < length $&) {
        push @ret, $i, length ($&) - $i;
        $greatestIndex = length $&;
      } else {
        next;
      }
      my $ref = 1;
      my @tmpRef = ();
      while (1) {
        my $tmp = $#tmpRef;
        eval "push \@tmpRef, \$$ref if (defined \$$ref)";
        last if ($#tmpRef == $tmp);
        $ref += 2;
      }
      unshift @tmpRef, ($ref - 1) / 2;
      push @ref, @tmpRef;
    }
  }
  
#say "ref: ", join ",", @ref;
  my @refCopy = @ref;
  while ($#refCopy > -1) {
    my $toShift = shift @refCopy;
    my @refPart;
    push @refPart, shift @refCopy foreach (1 .. $toShift);
    push @map, (0);
    my $mapCountIndex = $#map;
    foreach my $r (0 .. $#refPart) {
      $avant[2 * $r + 1] =~ /\{(.*),(.*)\}/;
      my $lower = $1;
      my $upper = $2;
      my $avant = $avant[2 * $r];
      $avant =~ s/\((.*)\)/$1/;
      my @letters = ();
      my @blacklist = ();
      my $todo = 1; # hack to make it enter the loop even if $lower is 0
      while ($todo || $#letters + 1 < $lower || $upper ne "" && $#letters > $upper) {
        $todo = 0;
        my $partCopy = $refPart[$r];
        if ($partCopy eq "") { # if it matched a word boundary
          unshift @letters, "";
          last;
        }
        my $matched;
        for (my $i = 0; ($upper eq "" || $upper > $i) && length $partCopy >= 1; $i++) {
          my $lookFor = blacken ($avant, $blacklist[$i]);
          $partCopy =~ s/($lookFor)$//;
          $matched = $1;
          unshift @letters, $matched;
        }
        if ($#letters + 1 < $lower || $upper ne "" && $#letters > $upper) {
          $blacklist[0] .= "|$letters[-1]";
          for (my $i = 0; $blacklist[$i] eq "|$avant"; $i++) {
            push @blacklist, "" x $i - $#blacklist + 1 if ($i > $#blacklist);
            $blacklist[$i] = "";
            $blacklist[$i + 1] .= "|$letters[-$i - 1]";
          }
          @letters = ();
        }
      }
#say "ltr: ", join ",", @letters;
      my @absMapCopy = @absMap;
      while ($#absMapCopy > -1) {
        if ($absMapCopy[0] == $scNum) {
          shift @absMapCopy;
          if ($absMapCopy[0] - 1 == $r) {
            shift @absMapCopy;
            my @old = split ("\\|", shift @absMapCopy);
            @old = (".") if ($old[0] =~ /^\(\?!/); # because of complements
#say "old: ", join ",", \@old;
            my $new = shift @absMapCopy;
            my $index = -1;
            my $apres;
            my $complement = "";
            foreach my $l (@letters) {
              foreach my $o (0 .. $#old) {
                $old[$o] =~ s/\\b//; # otherwise it would try to match "\b" which, of course, never shows up
#say "$old[$o] eq $l";
                if ($old[$o] eq $l) {
                  $index = $o;
                  last;
                }
                if ($old[$o] eq ".") {
                  $complement = $l;
                  last;
                }
              }
              unless ($index < 0) {
                $apres .= (split /\|/, $new)[$index];
              } else {
                $apres .= $complement; # word boundaries and complements
              }
            }
            $apres =~ s/\\b//;
            push @map, $apres;
            $map[$mapCountIndex]++;
          } else {
            shift @absMapCopy;
            shift @absMapCopy;
            shift @absMapCopy;
          }
        } else {
          shift @absMapCopy;
          shift @absMapCopy;
          shift @absMapCopy;
          shift @absMapCopy;
        }
      }
    }
  }
  foreach (@map) {
    $_ = "" unless (defined $_);
  }
#say "map: ", join ",", @map;
  return @ret;
}

sub blacken {
  my $white = "|" . shift;
  my $black = shift;
  $black = "" unless (defined $black);
  $white =~ s/$black//g;
  $white =~ s/^\|//;
  return $white;
}

sub replace {
  my $scNum = shift;
  my $word = shift;
  my $os = shift;
  my $pos = $os + shift;
  my $len = shift;
  my $avant = shift;
  my $apres = shift;
  my $pre = substr ($word, 0, $pos);
  my $post = substr ($word, $pos);
  
  die "Overly long word\n" if ($len > 32766);
  
  defined $apres ? eval "\$post =~ s/.\{$len\}/$apres/" : eval "\$post =~ s/.\{$len\}//"; 
  
  $os += length ("$pre$post") - length ($word);
  return ("$pre$post", $os);
}

######## CATEGORY SUBROUTINES ########

sub catContents {
  my $name = shift;
  my @fish;
  unless (exists $cats{$name}) {
    warn "Uninitialized category: <$name>\n";
    return ("");
  }
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return join ("|", @fish);
}

sub avantMain {
  my $scNum = shift;
  my @ret;
  OUTER: foreach (0 .. $#tentAvant) {
    next unless ($tentAvant[$_] =~ /^\d+$/);
    foreach (my $i = $_ + 1; $i <= $#tentAvant; $i += 2) {
      last OUTER if ($tentAvant[$i] =~ /^\d$/);
      push @ret, $tentAvant[$i];
    }
  }
  return @ret;
}

sub tentAvantCat {
  my $scNum = shift;
  my @ret;
  my @tentAvantCopy = @tentAvant;
  while ($#tentAvantCopy) {
    my $next = shift @tentAvantCopy;
    next unless ($next =~ /^\d+$/ && $next == $scNum);
    while ($#tentAvantCopy >= 0 && $tentAvantCopy[0] !~ /^\d+$/) {
      push @ret, shift @tentAvantCopy;
    }
    last;
  }
  return @ret;
}

sub avantCat {
  my $scNum = shift;
  my @ret;
  my @scAvantCopy = @scAvant;
  while ($#scAvantCopy) {
    my $next = shift @scAvantCopy;
    next unless ($next =~ /^\d+$/ && $next == $scNum);
    while ($#scAvantCopy >= 0 && $scAvantCopy[0] !~ /^\d+$/) {
      push @ret, shift @scAvantCopy;
    }
    last;
  }
  return @ret;
}

sub apresCat {
  my $scNum = shift;
  my @ret;
  my @scApresCopy = @scApres;
  while ($#scApresCopy) {
    my $next = shift @scApresCopy;
    next unless ($next =~ /^\d+$/ && $next == $scNum);
    while ($#scApresCopy >= 0 && $scApresCopy[0] !~ /^\d+$/) {
     push @ret, shift @scApresCopy;
    }
    last;
  }
  return @ret;
}

sub avantCatLength {
  my $scNum = shift;
  my $suffix = shift;
  return 0 if ($suffix == -1);
  my @avantMain = (0, avantMain ($scNum));
  my $ret = $avantMain[$suffix];
  $ret =~ s/^\(//;
  $ret =~ s/\)$//;
  return ($ret =~ tr/\|//);
}

sub avantCatContents {
  my $scNum = shift;
  my $suffix = shift;
  return 0 if ($suffix == -1);
  my @avantMain = (0, avantMain ($scNum));
  my $ret = $avantMain[$suffix];
  $ret =~ s/^\(//;
  $ret =~ s/\)$//;
  return $ret;
}

######## PRESENTATION SUBROUTINES ########

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/>$/> /; # hack to make deletions possible
  $string =~ s/^>/ >/; # hack to make empty-avant warnings work
  return $string;
}

sub edit {
  record (shift);
  my $text = shift;
  record ($text);
  if ($edit > 0) {
    record (" >>");
    my $input = <STDIN>;
    if (defined $input) {
      chomp $input;
      print $output $input if (defined $output);
    } else {
      $edit = -1;
      print $output $text if (defined $output);
      return ($text);
    }
    $input eq "" ? return $text : return $input;
  }
  return $text;
}

sub record {
  my $str = shift;
  print $str;
  print $output $str if (defined $output);
}