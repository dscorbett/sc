#!/bin/perl
# based on sounds.exe, with:
# backreferencing in the post
# no custom categories
# no word boundaries
use strict;
use warnings;
use feature "say";
use feature "switch";

open(WORDS, "<", "words.txt") or die "No words file.";
while (<WORDS>) {
  chomp;
  my $word = $_;
  say "word:     " . $word;
  open(RULES, "<", "rules.txt") or die "No rules file.";
  while (<RULES>) {
    chomp;
    my @rule = split / > /;
    my @ante = split(/\s/, $rule[0]);
    my @post = split(/\s/, $rule[1]);
    @ante = parseAnte(@ante);
    my $ante = join("", @ante);
    
    my $chopped = $word;
    my $index;
    my @replace;
    while ($chopped ne "") {
      if ($chopped =~ /($ante)/) {
        my $choppedIndex = index($chopped, $1);
        $index = index($word, $1, $choppedIndex);
        $chopped = substr($chopped, $choppedIndex + length $1);
        my $substring = $1;
        my @match;
        foreach (@ante) {
          @match = (@match, $1) if $substring =~ /($_)/;
        }
        $match[0] = $#match;
        my @repl = parsePost(@match, @post);
        my $repl = join("", @repl);
        my $length = length $substring;
        @replace = (@replace, $index, $length, $repl);
      } else {
        $chopped = substr($chopped, 1);
      }
    }
    
    my $offset = 0;
    for (my $i = 0; $i < @replace; $i += 3) {
      ($word, my $offsetAddend) = replace($word, @replace[$i..$i + 2], $offset);
      $offset += $offsetAddend;
      say " > $word";
    }
  }
  close RULES;
  say "new word: " . $word;
  print "\n";
}

sub parseAnte {
#  my %xsampa = { # from "X-SAMPA" on Wikipedia
#      bilabNasl => "m",
#    vlBilabPlos => "p",
#    vdBilabPlos => "b",
#    vlBilabFric => "p*",
#    vdBilabFric => "B",
#      bilabAppr => "B_o",
#      bilabTril => "B*",
#      bilabFlap => "V*_+",
#      labioNasl => "F",
#    vlLabioPlos => "p_d",
#    vdLabioPlos => "b_d",
#    vlLabioFric => "f",
#    vdLabioFric => "v",
#      labioAppr => "v*",
#      labioTril => "B*_d",
#      labioFlap => "V*",
#    vlDentlFric => "T",
#    vdDentlFric => "D",
#      alveoNasl => "n",
#    vlAlveoPlos => "t",
#    vdAlveoPlos => "d",
#    vlAlveoFric => "s",
#    vdAlveoFric => "z",
#      alveoAppr => "r*",
#      alveoTril => "r",
#      alveoFlap => "4",
#    vlAlveoLfrc => "K",
#    vdAlveoLfrc => "K*",
#      alveoLapp => "l",
#      alveoLflp => "l*",
#    vlPostaFric => "S",
#    vdPostaFric => "Z",
#      retroNasl => "n`",
#    vlRetroPlos => "t`",
#    vdRetroPlos => "d`",
#    vlRetroFric => "s`",
#    vdRetroFric => "z`",
#      retroAppr => "r*`",
#      retroTril => "4`",
#      retroFlap => "r`",
#    vlRetroLfrc => "K`",
#    vdRetroLfrc => "K*`",
#      retroLapp => "l`",
#      retroLflp => "l*`",
#      palatNasl => "J",
#    vlPalatPlos => "c",
#    vdPalatPlos => "J*",
#    vlPalatFric => "C",
#    vdPalatFric => "j*",
#      palatAppr => "j",
#      palatTril => "r_j",
#      palatFlap => "4_j",
#    vlPalatLfrc => "L_0_r",
#    vdPalatLfrc => "L_r",
#      palatLapp => "L",
#      palatLflp => "L_^",
#      velarNasl => "N",
#    vlVelarPlos => "k",
#    vdVelarPlos => "g",
#    vlVelarFric => "x",
#    vdVelarFric => "G",
#      velarAppr => "M*",
#    vlVelarLfrc => "L*_0_r",
#    vdVelarLfrc => "L*_r",
#      velarLapp => "L*",
#      velarLflp => "L*_^",
#      uvulaNasl => "N*",
#    vlUvulaPlos => "q",
#    vdUvulaPlos => "G*",
#    vlUvulaFric => "X",
#    vdUvulaFric => "R",
#    vlUvulaFric => "R_0_o",
#    vdUvulaFric => "R_o",
#      uvulaTril => "R*",
#      uvulaFlap => "R_X",
#      
#  };
  my @ante = "";
  foreach (@_) {
    if (m/^<[^>]*>$/) {
      given ($_) {
        when (/<vowel>/) {
          @ante = (@ante, "(a|e|i|o|u)");
        }
        when (/<consonant>/) {
          @ante = (@ante, "(a|e|i|o|u)");
        }
      }
    } else {
      @ante = (@ante, "(" . $_ . ")");
    }
  }
  return @ante;
}

sub parsePost {
  my $num = $_[0];
  my @match = @_[1..$num];
  my @post = @_[$num + 1..$#_];
  foreach (0..$#post) {
    #$post[$_] = $match[substr($post[$_], 1) - 1] if substr($post[$_], 0, 1) eq "\$";
    $post[$_] = $match[substr($post[$_], 1) - 1] if $post[$_] =~ /^\$\d+$/;
  }
  return @post;
}

sub replace { # ($word, @replace[$i..$i + 2], $offset)
  my $new = "";
  my $word = $_[0];
  my $index = $_[1] + $_[4]; # $_[4] is $offset;
  my $length = $_[2];
  my $replace = $_[3];
  print join(" ", @_);
  my $i = 0;
  for (my $i = 0; $i < length $word; $i++) {
    if ($i == $index) {
      $new .= $replace;
      $i += $length - 1;
    } else {
      $new .= substr($word, $i, 1);
    }
  }
  my $offsetAddend = length($new) - length($word);
  return ($new, $offsetAddend);
}