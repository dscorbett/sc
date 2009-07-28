#!/bin/perl
# slightly based on sc2.3.0.pl, with:
# faulty maps
use feature "say";
use strict;
use warnings;

######## RULES ########

open RULES, "<rules.txt" or die "rules.txt not found\n";
my %cats;
my @ref;
my @map;
my @mapCopy;
my @foo;
my @toShift;
my $scNum = 0;
my @scAvant;
my @scApres;
while (<RULES>) {
  next if (/^\s*($|!)/); # comment or blank line
  chomp;
  ($_) = split /!/, $_;
  if (/=/) {
    (my $cat, my $contents) = split /=/, $_, 2;
    $cat = trim ($cat);
    $contents = trim ($contents);
    die "Illegal character in category name: \"$1\"\n" if ($cat =~ /(\s|,)/);
    die "Illegal character in <$cat>: \"$1\"\n" if ($contents =~ /([(|)])/);
    die "Empty category: <$cat>\n" if ($contents =~ /^$/);
    die "Unit category: <$cat>\n" if ($contents !~ /\s/);
    my $tmp = [];
    push @$tmp, split /\s+/, $contents;
    $cats{$cat} = $tmp;
  } elsif (/ > /) {
    my @rule = split / > /;
    $rule[0] ne "" ? my @avant = split (/\s+/, $rule[0]) : die "No avant\n";
    my @apres = split (/\s+/, $rule[1]) if defined $rule[1];
    (my $avant, my $total) = parseAvant (@avant);
    push @scAvant, $avant;
    my $apres = parseApres ($total, $scNum, @apres);
    push @scApres, $apres;
    $scNum++;
  }
}
close RULES;

######## WORDS ########

open WORDS, "<words.txt" or die "words.txt not found\n";
while (<WORDS>) {
  chomp;
  print my $word = $_;
  my @index;
  @foo = (0);
  @mapCopy = @map;
  for (my $i = 0; $i <= $#scAvant; $i++) {
    next unless ($word =~ /$scAvant[$i]/);
    @index = regindex ($word, $scAvant[$i], 0, $i);
    my $offset = 0;
    while (@index > 0) {
      ($word, $offset) = replace ($i, $word, $offset, shift @index, shift @index, $scAvant[$i], $scApres[$i]);
      if (defined $toShift[0]) {
        shift @foo;
        my $toShift = shift @toShift;
        shift @foo for (0 .. $toShift);
        unshift @foo, 0;
      }
    }
    print " > $word";
  }
  say "";
}

######## SUBROUTINES ########

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
  
  eval "\$post =~ s/.\{$len\}/$apres/";
  $os += length ("$pre$post") - length ($word);
  return ("$pre$post", $os);
}

sub regindex {
  my $word = shift;
  my $regex = shift;
  my $index = shift; # always 0 for now
  my $scNum = shift;
  my @indices;
  @ref = (0);
  for (my $i = $index; $i < length $word; $i++) {
    if ($word =~ /(?:^.{$i})$regex/) {
      push @indices, ($i);
      push @indices, (length ($&) - $i);
      my $ref = 1;
      REF: while (1) {
        my $tmp = $#ref;
        eval "push \@ref, \$$ref if (defined \$$ref)";
        $ref++;
        last REF if ($#ref == $tmp);
      }
    }
  }
  
  my @refCopy = @ref;
  while ($#refCopy > 0) {
    while ($#mapCopy > 0) {
      shift @mapCopy;
      my $ref = shift @mapCopy;
      my @avantCat = split "\\|", shift @mapCopy;
      my $catIndex = -1;
      AVANT: for (0 .. $#avantCat) {
        if (defined $refCopy[$ref] && $refCopy[$ref] eq $avantCat[$_]) {
          $catIndex = $_;
          last AVANT;
        }
      }
      push @foo, @{$cats{shift @mapCopy}}[$catIndex];
    }
    shift @refCopy; # to get rid of initial 0
    shift @refCopy foreach (0 .. 1); # 2 is temp
    unshift @refCopy, 0; # putting it back
    @mapCopy = @map;
  }
  push @toShift, (($#indices - 1) / 2);
  return @indices;
}

sub parseAvant {
  my $avant;
  my $counter;
  foreach (@_) {
    $counter++;
    if (/^<([^>]+)>$/) {
      exists $cats{$1} ? $avant .= parseCat ($1) : die "Uninitialized category: <$1>";
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 < $counter ? $avant .= "(\\$1)" : die "Invalid backreference: \$$1\n";
    } elsif (/^#$/) {
      $avant .= "\\b";
    } else {
      $avant .= "($_)"; # TODO: die here if there is a pipe
    }
  }
  return ($avant, $counter);
}

sub parseApres {
  my $total = shift;
  my $scNum = shift;
  my $apres;
  my $counter;
  foreach (@_) {
    $counter++;
    if (/^<([^>]+)>/) {
      die "Uninitialized category: <$1>\n" unless (exists $cats{$1});
      die "Unspecified backreference for category <$1>\n" unless (/^<($1)>\$0*(\d+)$/);
      die "Invalid backreference for category <$1>: \$$2\n" unless ($2 ne "0" && $2 <= $total);
      die "Backreference to a literal: <$1>\n" unless avantType ($scNum, $2);
      die "Category length mismatch: <$1>\$$2\n" unless (catLength ($1) == avantCatLength ($scNum, $2));
#my $temp = avantCatContents ($scNum, $2);
#      $apres .= "($scNum, $2, $temp, $1)"; # TODO: temporary
      $apres .= "\$foo[$counter]";
      push @map, $scNum, $2, avantCatContents ($scNum, $2), $1;
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 <= $total ? $apres .= "\$ref[$1]" : die "Invalid backreference: \$$1\n";
    } else {
      $apres .= $_;
    }
  }
  return $apres;
}

sub parseCat {
  my $name = shift;
  my @fish;
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return "(" . join ("|", @fish) . ")";
}

sub catLength {
  my $name = shift;
  my @fish;
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return $#fish;
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

sub avantType { # 0 is literal, 1 is cat
  my $scNum = shift;
  my $num = shift;
  my $avant = $scAvant[$scNum];
  $avant =~ s/^\(//;
  $avant =~ s/\)$//;
  my @avant = split "\\)\\(", $avant;
  $avant[$num - 1] =~ /\|/ ? return 1 : return 0;
}

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}