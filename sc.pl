#!/bin/perl
# based on sc2.0.pl, with:
# simpler word boundaries
# no backreferencing
use feature "say";
use strict;
use warnings;

open RULES, "<rules.txt" or die "rules.txt not found";
my %cats;
while (<RULES>) {
  if (/ = /) {
    chomp;
    (my $cat, my $contents) = split / = /, $_, 4;
    die "Illegal character in category name: \"$1\"\n" if ($cat =~ /(\s)/);
    die "Illegal character in $cat: \"$1\"\n" if ($contents =~ /([(|)])/);
    die "Empty category: $cat\n" if ($contents =~ /^$/);
    $cats{$cat} = "(" . join '|', split / +/, $contents . ")";
  }
}
close RULES;

open RULES, "<rules.txt" or die "rules.txt lost";
my @rulesAv;
my @rulesAp;
while (<RULES>) {
  chomp;
  if (/ > /) {
    my @rule = split / > /;
    my @avant = split (/\s+/, $rule[0]);
    my @apres = split (/\s+/, $rule[1]);
    (my $avant, my $total) = parseAvant (@avant);
    my $apres = parseApres ($total, @apres);
    push @rulesAv, $avant;
    push @rulesAp, $apres;
  }
}
close RULES;

open WORDS, "<words.txt" or die "words.txt not found";
while (<WORDS>) {
  chomp;
  print my $word = $_;
  my @index = (0);
  for (my $i = 0; $i <= $#rulesAv; $i++) {
    my $av = $rulesAv[$i];
    my $ap = $rulesAp[$i];
    @index = regindex ($word, $av, $index[$#index]);
    if (1) {                                   #TODO: if the program should evaluate immediately
      eval "\$word =~ s/^(.{$_})$av/\$1$ap/" foreach (@index);
      print " > $word";
     @index = (0);
    }
  }
  #say " > $word";
}

sub parseAvant {
  my $avant;
  my $counter;
  foreach (@_) {
    $counter++;
    if (/^<([^>]+)>$/) {
      exists $cats{$1} ? $avant .= $cats{$1} : die "Uninitialized category: $1\n";
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 < $counter ? $avant .= "(\\$1)" : die "Invalid backreference: \$$1\n";
    } elsif (/^#$/) {
      $avant .= "\\b";
    } else {
      $avant .= "($_)";
    }
  }
  return ($avant, $counter);
}

sub parseApres {
  my $total = shift;
  my $apres;
  foreach (@_) {
    if (/^<([^>]+)>$/) {
      die "Use of category in apres: $1\n";
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 <= $total ? $apres .= "\$" . $1 : die "Invalid backreference: \$$1\n";
    } else {
      $apres .= $_;
    }
  }
  return $apres;
}

sub regindex {
  my $word = shift;
  my $regex = shift;
  my $index = shift;
  my @indices;
  for (my $i = $index; $i < length $word; $i++) {
    if ($word =~ /^.{$i}$regex/) {
      push @indices, ($i);
    }
  }
  return @indices;
}