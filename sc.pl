#!/bin/perl
# based on sc2.1.pl, with:
# the basis of intercategorialization
# comments
use feature "say";
use strict;
use warnings;

open RULES, "<rules.txt" or die "rules.txt not found";
my %cats;
my @rulesAv;
my @rulesAp;
my $total;
while (<RULES>) {
  next if (/^\s*($|#)/); # comment or blank line
  chomp;
  ($_) = split /#/, $_;
  if (/ = /) {
    (my $cat, my $contents) = split / = /, $_, 2;
    die "Illegal character in category name: \"$1\"\n" if ($cat =~ /(\s)/);
    die "Illegal character in $cat: \"$1\"\n" if ($contents =~ /([(|)])/);
    die "Empty category: $cat\n" if ($contents =~ /^$/);
    my $tmp = [];
    push @$tmp, split / +/, $contents;
    $cats{$cat} = $tmp;
  } elsif (/ > /) {
    my @rule = split / > /;
    my @avant = split (/\s+/, $rule[0]);
    my @apres = split (/\s+/, $rule[1]);
    (my $avant, $total) = parseAvant (@avant);
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
    unless (0) {                             #TODO: unless the program should wait
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
      exists $cats{$1} ? $avant .= parseCat ($1) : die "Uninitialized category: <$1>\n";
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
    if (/^<([^>]+)>/) { # was /^<([^>]+)>$/
      #die "Use of category in apres: $1\n";
      die "Uninitialized category: <$1>\n" unless (exists $cats{$1});
      die "Unspecified backreference for category <$1>: " unless (/^<$1>\$0*(\d+)$/);
      die "Invalid backreference: \$$1\n" unless ($1 ne "0" && $1 == $total);
      
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 <= $total ? $apres .= "\$" . $1 : die "Invalid backreference: \$$1\n";
    } else {
      $apres .= $_;
    }
  }
  return $apres;
}

sub parseCat {
  my @fish;
  foreach (0 .. $#{$cats{vowel}}) {
    push @fish, @{$cats{vowel}}[$_];
  }
  return "(" . join ("|", @fish) . ")";
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