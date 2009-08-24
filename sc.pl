#!/bin/perl
# based on sc3.2.pl and sc3.3.pl, with:
# regex quantifiers
# word boundaries

# TODO:
# quantifiers: backreferencing to one only returns the last matched, not the whole string
# retest editing
# Unicode support
# merging of redundant code
# reorganization of code
# reorganization of escaped Perl regex characters
# presentation
# documentation

use feature "say";
use utf8;
use strict;
use warnings;

######## COMMAND-LINE ARGUMENTS ########

my $rules = "rules.txt";
my $words;
my @words;
my $output;
my $limit = 10000;
my $mode = 2; # 0 = superbrief; 1 = brief; 2 = verbose
my @clWords;
my %cond;
my $edit = 0;

foreach (@ARGV) {
  (/^-(?:r|rules)=(.+)$/i) ? $rules = $1 :
  (/^-(?:w|words)=(.+)$/) ? $words = $1 :
  (/^-(?:o|output)=(.+)$/i) ? $output = $1 :
  (/^-(?:l|limit)=(\d+)$/i) ? $limit = $1 :
  (/^-(?:m|mode)=(\d+)$/i) ? $mode = $1 :
  (/^-(?:c|cond)=(.+)$/i) ? $cond{uc $1} = "" :
  (/^-(?:e|edit)$/i) ? $edit = 1 :
  push @clWords, $_;
}

if (defined $output) {
  open OUTPUT, ">", $output or warn "$output not found\n"; # :encoding(utf8)
  $output = *OUTPUT;
}

$words = "words.txt" unless (defined $words || $#clWords > -1);
if (defined $words) {
  open WORDS, "<", $words or die "$words not found\n"; # :encoding(utf8)
  chomp(@words = <WORDS>);
  close WORDS;
}
push @words, @clWords;


######## VARIABLES ########

my %cats;
my @ref;
my @map;
my @foo;
my $scNum = 0;
my @scAvant;
my @scApres;
my @min;
my @max;
my $dialect = "";
my @scLects;
my @scPersist;
my @scRepeat;
my @scPersistRepeat;
my $skip = 0; # 0 = noskip; 1 = skip; 2 = end

######## RULES ########

open RULES, "<", $rules or die "$rules not found\n"; # :encoding(utf8)
RULE: while (<RULES>) {
  next if ($skip == 2);
  next if (/^\s*($|!)/); # comment or blank line
  chomp;
  ($_) = split /!/, $_;
  $_ = trim ($_);
  
  my $skipping = 0;
  if (/^(SKIP|NOSKIP|END)\b/i) {
    if (/^SKIP\b/i) {
      if (/^SKIP\s+(IF|UNLESS)\s+(.+)/i) {
        next RULE if ($1 eq uc "IF" && !exists $cond{uc $2});
        next RULE if ($1 eq uc "UNLESS" && exists $cond{uc $2});
      }
      $skip = 1;
    } elsif (/^NOSKIP\b/i) {
      if (/^NOSKIP\s+(IF|UNLESS)\s+(.+)/i) {
        next RULE if ($1 eq uc "IF" && !exists $cond{uc $2});
        next RULE if ($1 eq uc "UNLESS" && exists $cond{uc $2});
      }
      $skip = 0;
    } elsif (/^END\b/i) {
      if (/^END\s+(IF|UNLESS)\s+(.+)/i) {
        next RULE if ($1 eq uc "IF" && !exists $cond{uc $2});
        next RULE if ($1 eq uc "UNLESS" && exists $cond{uc $2});
      }
      $skip = 2;
    }
    $skipping = 1;
  }
  next if ($skip);
  if (/^\[(.*)\]$/) {
    $dialect .= $1;
  } elsif (/ > /) {
    my @rule = split / > /;
    if ($rule[0] ne "") {
      my @avant = split (/\s+/, $rule[0]);
      if ($avant[0] =~ /\[(.*)\]/) {
        push @scLects, $1;
        shift @avant;
      }
      
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
      
      (my $avant, my $total) = parseAvant (@avant);
      next RULE if ($total == -1);
      push @scAvant, $avant;
      
      (my $apres, my $check) = parseApres ($total, $scNum, @apres);
      unless ($check == 1) {
        pop @scAvant;
        next RULE;
      }
      push @scApres, $apres;
      
      $scNum++;
    } else {
      warn "Rule found without original form\n";
    }
  } elsif (/=/) {
    (my $cat, my $contents) = split /=/, $_, 2;
    $cat = trim ($cat);
    $contents = trim ($contents);
    addCat ($cat, $contents);
  } else {
    warn "Unparsable statement \"$_\" ignored\n" unless ($skipping);
  }
  warn "Ambiguous statement \"$_\" parsed as sound change\n" if (/=/ && / > /);
}
close RULES;

say "av.: ", join ",", @scAvant;

######## WORDS ########

#say "min: ", join ",", @min;
#say "max: ", join ",", @max;

$dialect = " " if ($dialect eq "");
foreach my $dial (split //, $dialect) {
  record ("$dial:\n") if (length $dialect > 1);
  foreach (@words) {
    chomp;
    my $word = " $_ ";
    record (trim ($word));
    my @index;
    SC: for (my $i = 0; $i <= $#scAvant; $i++) {
      my $old = $word;
      next SC unless ($dialect eq " " || !defined ($scLects[$i]) || $scLects[$i] =~ /$dial/);
      next SC if (join (",", @scPersist) =~ /$i/);
      @index = regindex ($word, $scAvant[$i], $i);
      my $offset = 0;
      while (@index > 0) {
#say "ref: ", join ",", @ref;
#say "map: ", join ",", @map;
        ($word, $offset) = replace ($i, $word, $offset, shift @index, shift @index, $scAvant[$i], $scApres[$i]);
        my $refShift = shift @ref;
        shift @ref foreach (1 .. $refShift);
        my $fooShift = shift @foo;
        shift @foo foreach (1 .. $fooShift);
      }
      $word = edit (" >", $word) if ($mode >= 2);
      $limit--;
      die "\nQuitting due to possible infinite repetition\n" if ($limit == 0);
      
      record (" [") if ($#scPersist > -1 && $mode >= 2);
      PSC: for (my $j = 0; $j <= $#scAvant; $j++) {
        my $oldP = $word;
        next PSC unless ($dialect eq " " || !defined ($scLects[$j]) || $scLects[$j] =~ /$dial/);
        next PSC unless (join (",", @scPersist) =~ /$j/);
        @index = regindex ($word, $scAvant[$j], $j);
        my $offset = 0;
        while (@index > 0) {
          ($word, $offset) = replace ($j, $word, $offset, shift @index, shift @index, $scAvant[$j], $scApres[$j]);
          my $refShift = shift @ref;
          shift @ref foreach (1 .. $refShift);
          my $fooShift = shift @foo;
          shift @foo foreach (1 .. $fooShift);
        }
        $word = edit (" > ", $word) if ($mode >= 2);
        $limit--;
        die "\nQuitting due to possible infinite repetition\n" if ($limit == 0);
        $j-- if (join (",", @scPersistRepeat) =~ /$j/ && $word =~ /$scAvant[$j]/ && $word ne $oldP);
      }
      record ("]") if ($#scPersist > -1 && $mode >= 2);
      $word = edit (" > ", $word) if ($mode == 1);
      $i-- if (join (",", @scRepeat) =~ /$i/ && $word =~ /$scAvant[$i]/ && $word ne $old);
    }
    $word = edit (" > ", $word) if ($mode <= 0);
    record ("\n");
  }
}

######## PARSING SUBROUTINES ########

sub parseAvant {
  my $avant;
  my $counter = 0;
  my @tmpMin;
  my @tmpMax;
  foreach (@_) {
    $counter++;
    #$_ =~ s/(\\|\^|\*|\?|\.|\(|\)|\}|\[|\]|\{)/\\$1/; # useful?
    $_ =~ s/\$0*(\d+)/\\$1/;
    #$_ =~ s/\$/\\\$/;
    
    my $min = 1;
    my $max = 1;
    if (/\*$/) {
      $min = 0;
      $max = "";
    } elsif (/\+$/) {
      $min = 1;
      $max = "";
    } elsif (/\?$/) {
      $min = 0;
      $max = 1;
    } elsif (/\{(.*)\}/) {
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
    }
    if ($max ne "" && $min > $max) {
      my $tmp = $min;
      $min = $max;
      $max = $tmp;
    }
    push @tmpMin, $min;
    push @tmpMax, $max;
    
    $_ =~ s/(\{(.*)\}|\*|\+|\?)$//;
    
    my $part;
    $_ =~ s/>(?!\+|-|\|)(?=.+)/>+/; # put a + between > and any non-(+-|)
    $_ =~ s/([^+-|])</$1+</; # put a + between any non-(+-|) and <
    $_ =~ s/>\|</>+</g; # change | to + between categories
    $_ =~ s/#/ /; # word boundaries
    
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
          return ("", -1) if ($contents eq "");
          push @minus, split /\|/, $contents;
        } else {
          push @minus, $mPiece;
        }
      }
    }
    if (defined $part) {
      foreach my $del (@minus) {
        $part =~ s/\|$del//g;
      }
    } else {
      $part = "?!";
      foreach my $del (@minus) {
        $part .= $del . "|";
      }
      $part =~ s/\|$//;
    }
    if (!defined $part || $part eq "") {
      warn "Useless empty string in the first half of rule ", $scNum + 1, "\n";
      return ("", -1);
    }
    $part =~ s/^\|//;
    $part =~ s/\|$//;
    $avant .= "($part)";
  }
  unshift @tmpMin, $#_ + 1;
  unshift @tmpMax, $#_ + 1;
  push @min, @tmpMin;
  push @max, @tmpMax;
  return ($avant, $counter);
}

sub parseApres {
  my $total = shift;
  my $scNum = shift;
  my $apres = "";
  my $counter;
  my $fooCounter;
  return ("", 1) if ($_[0] eq ""); # special case for deletions
  foreach (@_) {
    $counter++;
    $_ =~ s/(\\|\^|\*|\?|\.|\(|\))/\\$1/; # this is a new line
    my $suffix;
    if (/\$0*(\d+)$/) {
      $suffix = $1;
    } else {
      $suffix = -1;
    }
    $_ =~ s/\$0*(\d+)$//;
    if ($suffix eq "0" || $suffix > $total) {
      warn "Invalid backreference for $_: \$$suffix\n";
      return ("", 0);
    }
    
    my $part;
    $_ =~ s/>(?!\+|-|\|)(?=.+)/>+/g; # put a + between > and any non-(+-|)
    $_ =~ s/([^+-|])</$1+</g; # put a + between any non-(+-|) and <
    $_ =~ s/>\|</>+</g; # change | to + between categories
    my @pieces = split /(?=\+|^|-)/, $_;
    
    unless ($#pieces == -1) {
      foreach my $piece (@pieces) {
        next if ($piece =~ /^-/);
        $piece =~ s/\+//;
        if ($piece =~ /^<(.*)>$/) {
          my $contents = catContents ($1);
          return ("", 0) if ($contents eq "");
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
        $part =~ s/\|$del//g;
      }
      if (!defined $part || $part eq "") {
        warn "Useless empty string in the second half of rule ", $scNum + 1, "\n";
        return ("", 0);
      }
      $part =~ s/^\|//;
    } else {
      $part = avantCatContents ($scNum, $suffix);
    }
    
    # In the following, defined $part is for when there is a deletion (i.e. no apres)
    if (defined $part && $suffix == -1 && ($part =~ tr/\|//) != 0) {
      warn "Unspecified backreference for <$part>\n";
      return ("", 0);
    }
    unless ($suffix ne "0" && $suffix <= $total) {
      warn "Invalid backreference: \$$suffix\n";
      return ("", 0);
    }
    if (defined $part && ($part =~ tr/\|//) != avantCatLength ($scNum, $suffix)) {
      my $x = ($part =~ tr/\|//);
      warn "Category length mismatch: <$part>\$$suffix (" . (avantCatLength ($scNum, $suffix) + 1) . " != " . ($x + 1) . ")\n";
      return ("", 0);
    }
    unless ($suffix == -1) {
      $fooCounter++;
      $apres .= "\$foo[$fooCounter]";
      push @map, $scNum, $suffix, avantCatContents ($scNum, $suffix), $part;
    } elsif (defined $part) {
      $apres .= $part;
    }
  }
  return ($apres, 1);
}

######## SOUND-CHANGING SUBROUTINES ########

sub regindex {
  my $word = shift;
  my $regex = shift;
  my $scNum = shift;
  $regex = quant ($regex, $scNum);
  my @indices;
  @ref = ();
  my @qRef = ();
#say "";
  for (my $i = 0; $i < length $word; $i++) {
    die "\nQuitting due to overly long word\n" if ($i > 32766);
#say "$word =~ /(?:^.{$i})$regex/";
    if ($word =~ /(?:^.{$i})$regex/) {
      push @indices, ($i);
      push @indices, (length ($&) - $i);
      my $ref = 2;
      my @tmpRef = ();
      REF: while (1) {
        my $tmp = $#tmpRef;
        eval "push \@tmpRef, \$$ref if (defined \$$ref)";
        last REF if ($#tmpRef == $tmp);
        $ref += 2;
      }
      unshift @tmpRef, ($ref - 2) / 2;
      push @ref, @tmpRef;
      
      $ref = 1;
      my @tmpQRef = ();
      QREF: while (1) {
        my $tmp = $#tmpQRef;
        eval "push \@tmpQRef, \$$ref if (defined \$$ref)";
        last QREF if ($#tmpQRef == $tmp);
        $ref += 2;
      }
      unshift @tmpQRef, ($ref - 1) / 2;
      push @qRef, @tmpQRef;
    }
  }
  

say "qRef:", join ",", @qRef;

  my @mapCopy;
  my @refCopy;
  @refCopy = @ref;
  @foo = ();
#say "refC: ", join ",", @refCopy;
  while (@refCopy > 0) {
    push @foo, 0;
    my $incMatches;
    $incMatches = $#foo;
    my @mapCopy = @map;
    while (@mapCopy > 0) {
      if ($mapCopy[0] == $scNum) {
        shift @mapCopy;
        my $refIndex = shift @mapCopy;
#say ":$refIndex:$refCopy[$refIndex]:";
        my $string = $refCopy[$refIndex];
        my $qString = $qRef[$refIndex];
        
        my $matches = 0;
        unless ($string eq "") {
          $matches++ while ($qString =~ /($string){$matches}/);
          $matches--;
        }
#say "\nmch: $matches ($string in $qString)";
        
        my @avantCat = split ("\\|", shift @mapCopy); 
        my $index = -1;
        foreach (0 .. $#avantCat) {
          last unless (defined $string);
          $index = $_;
          last if ($avantCat[$_] eq $string);
        }
        my $apString = shift @mapCopy;
        # If there is no match ($index is -1) it takes the last index by default.
        my $newString = (split "\\|", $apString)[$index];
        unless ($newString =~ / /) {
          push @foo, $newString;
          $foo[$incMatches]++;
        }
      } else {
        shift @mapCopy;
        shift @mapCopy;
        shift @mapCopy;
        shift @mapCopy;
      }
    }
    defined $refCopy[0] ? my $refShift = shift @refCopy : last;
    shift @qRef;
    foreach (1 .. $refShift) {
      shift @refCopy;
      shift @qRef;
    }
  }
say "ref: ", join ",", @ref;
#say "qRef:", join ",", @qRef;
say "map: ", join ",", @map;
say "foo: ", join ",", @foo;
  return @indices;
}

sub quant {
  my $regex = shift;
  my $scNum = shift;
  my @regex = $regex =~ /\((.*?)\)/g;
  
  my @minCopy = @min;
  my @maxCopy = @max;
  my @realMin;
  my @realMax;
  my $loops = 0;
#  foreach (@minCopy) {
#    if ($scNum == $loops) {
#      my $next = shift @minCopy;
#      shift @maxCopy;
#      @realMin = @minCopy[0 .. $next - 1];
#      @realMax = @maxCopy[0 .. $next - 1];
#      last;
#    } else {
#      shift @maxCopy;
#      foreach (1 .. shift @minCopy) {
#        shift @minCopy;
#        shift @maxCopy;
#      }
#    }
#    $loops++;
#  }
  while ($scNum != $loops) {
    $loops++;
    my $qShift = shift @minCopy;
    shift @maxCopy; # to match @minCopy
    foreach (1 .. $qShift) {
      shift @minCopy;
      shift @maxCopy;
    }
  }
  my $qShift = $minCopy[0];
  foreach (1 .. $qShift) {
    push @realMin, $minCopy[$_];
    push @realMax, $maxCopy[$_];
  }
say "\n[", join (",", @minCopy), "][", join (",", @maxCopy), "]";
say "[", join (",", @min), "][", join (",", @max), "]";
say "[", join (",", @realMin), "][", join (",", @realMax), "]";
  my $return;
  foreach (0 .. $#regex) {
    if ($regex[$_] =~ /\\b/) {
      $return .= "$regex[$_]";
    } elsif (defined ($realMax[$_])) {
      $return .= "(($regex[$_]){$realMin[$_],$realMax[$_]})";
    } else {
      $return .= "(($regex[$_]){$realMin[$_],})"; # sth screws up realM__ up w/ >2 rules
    }
  }
  return $return;
}

sub replace {
  my $scNum = shift;
  my $word = shift;
  my $os = shift;
  my $pos = shift() + $os;
  my $len = shift;
  my $avant = shift;
  my $apres = shift;
  my $pre = substr ($word, 0, $pos);
  my $post = substr ($word, $pos);
  
  die "Overly long word\n" if ($len > 32766);
  
  # The double nature of the following is to circumvent its complaint of an uninitialized $apres.
  defined $apres ? eval "\$post =~ s/.\{$len\}/$apres/" : eval "\$post =~ s/.\{$len\}//"; 
  $os += length ("$pre$post") - length ($word);
  return ("$pre$post", $os);
}

######## CATEGORY SUBROUTINES ########

sub addCat { # could also go in PARSING SUBROUTINES under the name parseCat
  my $cat = shift;
  if($cat =~ /(\s|\+|-)/) {
    warn "Illegal character in <$cat>'s name: \"$1\"";
    return;
  }
  my $contents = shift;
  my @contents = split /\s+/, $contents;
  my $tmp = [];
  
  foreach (@contents) {
    my $part;
    $_ =~ s/>(?!\+|-|\|)(?=.+)/>+/g; # put a + between > and any non-(+-|)
    $_ =~ s/([^+-|])</$1+</g; # put a + between any non-(+-|) and <
    $_ =~ s/>\|</>+</g; # change | to + between categories
    $_ =~ s/#/ /; # word boundaries
    $_ =~ s/(\\|\$|\^|\*|\?|\.|\(|\))/\\$1/;
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
    if (!defined $part || $part eq "") {
      warn "Useless empty category <$cat>\n";
      return;
    }
    
    $part =~ s/^\|//;
    push @$tmp, split /\|/, $part;
  }
  $cats{$cat} = $tmp;
}

sub catArray {
  my $name = shift;
  my @fish;
  die "No such category: <$name>\n" unless (defined @{$cats{$name}});
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return @fish;
}

sub catLength {
  my $name = shift;
  my @fish;
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return $#fish;
}

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

sub avantType { # 0 is literal, 1 is cat
  my $scNum = shift;
  my $suffix = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  $avant[$suffix - 1] =~ /\|/ ? return 1 : return 0;
}

sub avantCatLength {
  my $scNum = shift;
  my $suffix = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  unless ($suffix == -1) {
    my @avantPart = split "\\|", $avant[$suffix - 1];
    return $#avantPart;
  }
  # This is for strings without suffixes, i.e literals. It is 0 for 1 is added above.
  return 0;
}

sub avantCatContents {
  my $scNum = shift;
  my $suffix = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  if ($suffix == -1) {
    $avant = $avant[0]
  } else {
    $avant = $avant[$suffix - 1]
  }
  $avant =~ s/^\(\?://;
  $avant =~ s/\)\{.*?\}$//;
  return $avant;
}

######## PRESENTATION SUBROUTINES ########

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  $string =~ s/>$/> /; # hack to make deletions possible
  return $string;
}

sub edit {
  record (shift);
  my $text = shift;
  record ($text);
  if ($edit) {
    record (" >>");
    my $input = <STDIN>;
    if (defined $input) {
      chomp $input;
      print $output $input if (defined $output);
    } else {
      $edit = 0;
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
