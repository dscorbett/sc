#!/bin/perl
# based on sc3.0.pl, with:
# mappings
# "#" no longer a phoneme
# categories in other category definitions
# warnings instead of death
# dialects
# persistant sound changes
# repetitive sound changes
# no deletions

# TODO:
# unified category parsing for both avant and apres
# other category formats
# run-time word editing
# Geoff's modifiers
# command-line arguments
# Geoff's directives and conditions
# merging of redundant code
# reorganization of code
# presentation
# documentation

use feature "say";
use strict;
use warnings;

######## RULES ########

my %cats;
my @ref;
my @map;
my @foo;
my $scNum = 0;
my @scAvant;
my @scApres;
my $dialect = "";
my @scLects;
my @scPersist;
my @scRepeat;

open RULES, "<rules.txt" or die "rules.txt not found\n";
RULE: while (<RULES>) {
  next if (/^\s*($|!)/); # comment or blank line
  chomp;
  ($_) = split /!/, $_;
  $_ = trim ($_);
  
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
      
      my @apres = split (/\s+/, $rule[1]) if defined $rule[1];
      if ($apres[-1] =~ /\[(.*)\]/) {
        if ($1 =~ /P/i) {
          push @scPersist, $scNum;
        }
        if ($1 =~ /R/i) {
          push @scRepeat, $scNum;
        }
        pop @apres;
      }
      
      (my $avant, my $total) = parseAvant (@avant);
      next RULE if ($total == -1);
      push (@scAvant, $avant);
      
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
#   my $tmp = # Why was this temperary variable necessary?
    addCat ($cat, $contents);
  } else {
    warn "Unparsable statement \"$_\" ignored\n";
  }
  warn "Ambiguous statement \"$_\" parsed as sound change\n" if (/=/ && / > /);
}
close RULES;

######## WORDS ########

$dialect = " " if ($dialect eq "");
foreach my $dial (split //, $dialect) {
  say "$dial:" if (length $dialect > 1);
  open WORDS, "<words.txt" or die "words.txt not found\n";
  while (<WORDS>) {
    chomp;
    print my $word = $_;
    my @index;
    SC: for (my $i = 0; $i <= $#scAvant; $i++) {
      next SC unless ($dialect eq " " || !defined ($scLects[$i]) || $scLects[$i] =~ /$dial/);
      next SC if (join (",", @scPersist) =~ /$i/);
      @index = regindex ($word, $scAvant[$i], 0, $i);
      my $offset = 0;
      while (@index > 0) {
        ($word, $offset) = replace ($i, $word, $offset, shift @index, shift @index, $scAvant[$i], $scApres[$i]);
        my $refShift = shift @ref;
        shift @ref foreach (1 .. $refShift);
        my $fooShift = shift @foo;
        shift @foo foreach (1 .. $fooShift);
      }
      print " > $word";
      
      print " [" if ($#scPersist > -1);
      PSC: for (my $j = 0; $j <= $#scAvant; $j++) {
        next PSC unless ($dialect eq " " || !defined ($scLects[$j]) || $scLects[$j] =~ /$dial/);
        next PSC unless (join (",", @scPersist) =~ /$j/);
        @index = regindex ($word, $scAvant[$j], 0, $j);
        my $offset = 0;
        while (@index > 0) {
          ($word, $offset) = replace ($j, $word, $offset, shift @index, shift @index, $scAvant[$j], $scApres[$j]);
          my $refShift = shift @ref;
          shift @ref foreach (1 .. $refShift);
          my $fooShift = shift @foo;
          shift @foo foreach (1 .. $fooShift);
        }
        print " > $word";
      }
      print "]" if ($#scPersist > -1);
      
      $i-- if (join (",", @scRepeat) =~ /$i/ && $word =~ /$scAvant[$i]/);
    }
    say "";
  }
}

######## PRIMARY SUBROUTINES ########

sub parseAvant {
  my $avant;
  my $counter = 0;
  foreach (@_) {
    $counter++;
    if (/^<([^>]+)>$/) {
      if (exists $cats{$1}) {
        $avant .= catContents ($1);
      } else {
        warn "Uninitialized category: <$1>\n";
        return ("", -1);
      }
    } elsif (/^\$0*(\d+)$/) {
      if ($1 ne "0" && $1 < $counter) {
        $avant .= "(\\$1)";
      } else {
        warn "Invalid backreference: \$$1\n";
        return ("", -1);
      }
    } elsif (/^#$/) {
      $avant .= "\\b";
      $counter--; # because "#" is not a phoneme
    } else {
      $avant .= "($_)";
    }
  }
  return ($avant, $counter);
}

sub parseApres {
  my $total = shift;
  my $scNum = shift;
  my $apres;
  my $counter;
  my $mapCounter;
  foreach (@_) {
    $counter++;
    if (/^<([^>]+)>/) {
      unless (exists $cats{$1}) {
        warn "Uninitialized category: <$1>\n";
        return ("", 0);
      }
      unless (/^<($1)>\$0*(\d+)$/) {
        warn "Unspecified backreference for category <$1>\n";
        return ("", 0);
      }
      if ($2 eq "0" || $2 > $total) {
        warn "Invalid backreference for category <$1>: \$$2\n";
        return ("", 0);
      }
      #die "Backreference to a literal: <$1>\n" unless avantType ($scNum, $2); # No reason for death here
      unless (catLength ($1) == avantCatLength ($scNum, $2)) {
        warn "Category length mismatch: <$1>\$$2\n";
        return ("", 0);
      }
      
      $mapCounter++;
      $apres .= "\$foo[$mapCounter]"; # was "\$foo[$counter]"
      push @map, $scNum, $2, avantCatContents ($scNum, $2), $1;
    } elsif (/^\$0*(\d+)$/) {
      if ($1 ne "0" && $1 <= $total) {
        $apres .= "\$ref[$1]";
      } else {
        warn "Invalid backreference: \$$1\n";
        return ("", 0);
      }
    } else {
      $apres .= $_;
    }
  }
  return ($apres, 1);
}

sub regindex {
  my $word = shift;
  my $regex = shift;
  my $index = shift; # always 0 for now
  my $scNum = shift;
  my @indices;
  @ref = ();
  for (my $i = $index; $i < length $word; $i++) {
    if ($word =~ /(?:^.{$i})$regex/) {
      push @indices, ($i);
      push @indices, (length ($&) - $i);
      my $ref = 1;
      my @tmpRef = ();
      REF: while (1) {
        my $tmp = $#tmpRef;
        eval "push \@tmpRef, \$$ref if (defined \$$ref)";
        last REF if ($#tmpRef == $tmp);
        $ref++;
      }
      unshift @tmpRef, ($ref - 1);
      push @ref, @tmpRef;
    }
  }
  
  my @mapCopy;
  my @refCopy;
  @refCopy = @ref;
  
  @foo = ();
  while (@refCopy > 0) {
    push @foo, 0;
    my $incMatches;
    $incMatches = $#foo;
    my @mapCopy = @map;
    while (@mapCopy > 0) {
      if ($mapCopy[0] == $scNum) {
        shift @mapCopy;
        my $string = $refCopy[shift @mapCopy];
        my @avantCat = split ("\\|", shift @mapCopy);
        my $index;
        foreach (0 .. $#avantCat) {
          $index = $_;
          last if ($avantCat[$_] eq $string);
        }
        my $catName = shift @mapCopy;
        my $newString = ${$cats{$catName}}[$index];
        push @foo, $newString;
        $foo[$incMatches]++;
      } else {
        shift @mapCopy;
        shift @mapCopy;
        shift @mapCopy;
        shift @mapCopy;
      }
    }
    defined $refCopy[0] ? my $refShift = shift @refCopy : last;
    shift @refCopy foreach (1 .. $refShift);
  }
  return @indices;
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
  
  # The double nature of the following is to circumvent its complaint of an uninitialized $apres.
  defined $apres ? eval "\$post =~ s/.\{$len\}/$apres/" : eval "\$post =~ s/.\{$len\}//"; 
  $os += length ("$pre$post") - length ($word);
  return ("$pre$post", $os);
}

######## CATEGORY SUBROUTINES ########

sub addCat {
  my $cat = shift;
  my $contents = shift;
  if ($cat =~ /(\s|,|\||\+|-)/) {
    warn "Illegal character \"$1\" in category name: <$cat>\n";
    return;
  }
  if ($contents =~ /([(|)])/) {
    warn "Illegal character in <$cat>: \"$1\"\n";
    return;
  }
  if ($contents =~ /^$/) {
    warn "Empty category: <$cat>\n";
    return;
  }
  #die "Unit category: <$cat>\n" if ($contents !~ /\s/); # No reason for death here
  
  my $tmp = [];
  my @contents = split /\s+/, $contents;
  foreach (@contents) {
    if (/^<([^>]+)>$/) {
      my @subcat = catArray ($1);
      push @$tmp, $_ foreach (@subcat);
    } elsif (/^#$/) {
      push @$tmp, "\\b";
    } else {
      push @$tmp, $_;
    }
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
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return "(" . join ("|", @fish) . ")";
}

sub avantType { # 0 is literal, 1 is cat
  my $scNum = shift;
  my $num = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  $avant[$num - 1] =~ /\|/ ? return 1 : return 0;
}

sub avantCatLength { # when it is already known that $scAvant[$scNum]'s $num-th piece is a cat
  my $scNum = shift;
  my $num = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  my @avantPart = split "\\|", $avant[$num - 1];
  return $#avantPart;
}

sub avantCatContents { # as above
  my $scNum = shift;
  my $num = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  return $avant[$num - 1];
}

######## OTHER SUBROUTINES ########

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}