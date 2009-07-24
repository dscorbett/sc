#!/bin/perl
# based on sc1.pl, with:
# no banana problem
# custom categories
# backreferencing in the ante
# word boundaries
use strict;
use warnings;
use feature "say";

open RULES, "<rules.txt" or die "No rules file.";
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

open RULES, "<rules.txt" or die "rules.txt not found";
my @rulesA;
my @rulesP;
while (<RULES>) {
  if (/ > /) {
    my @rule = split / > /;
    my @ante = split(/\s+/, $rule[0]);
    my @post = split(/\s+/, $rule[1]);
    (my $ante, my $total) = parseAnte (@ante);
    my $post = parsePost ($total, @post);
    
    push @rulesA, $ante;
    push @rulesP, $post;
  }
}
close RULES;

open WORDS, "<words.txt" or die "words.txt not found";
while (<WORDS>) {
  chomp;
  print my $word = $_;
  for (my $i = 0; $i <= $#rulesA; $i++) {
    my $a = $rulesA[$i];
    my $p = $rulesP[$i];
    my $s = "\$word =~ s/$a/$p/g";
    eval $s;
  }
  say " > $word";
}

sub parseAnte {
  my $ante;
  my $counter;
  foreach (@_) {
    $counter++;
    if (/^<([^>]*)>$/) {
      exists $cats{$1} ? $ante .= $cats{$1} : die "Uninitialized category: $1\n";
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 < $counter ? $ante .= "(\\" . $1 . ")" : die "Invalid backreference: \$$1\n";
    } elsif (/^#$/) {
      if ($counter == 1) {
        $ante .= "^";
      } else {
        $ante .= "\$";
      }
    } else {
      $ante .= "(" . $_ . ")";
    }
  }
  return ($ante, $counter);
}

sub parsePost {
  my $total = shift;
  my $post;
  foreach (@_) {
    if (/^<([^>]*)>$/) {
      die "Use of category in post: $1\n";
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 <= $total ? $post .= "\$" . $1 : die "Invalid backreference: \$$1\n";
    } else {
      $post .= $_;
    }
  }
  return $post;
}