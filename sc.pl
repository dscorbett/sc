#!/bin/perl
# based on sc2.3.1.pl
use feature "say";
use strict;
use warnings;

open RULES, "<rules.txt" or die "rules.txt not found";
my %cats;
my @r;
my @map;
my @currMap;
my @rulesAv;
my @rulesAp;
my $total;
my $ruleNo = 0;
while (<RULES>) {
  next if (/^\s*($|!)/); # comment or blank line
  chomp;
  ($_) = split /!/, $_;
  if (/=/) {
    (my $cat, my $contents) = split /=/, $_, 2;
    $cat = trim ($cat);
    $contents = trim ($contents);
    die "Illegal character in category name: \"$1\"\n" if ($cat =~ /(\s|,)/);
    die "Illegal character in $cat: \"$1\"\n" if ($contents =~ /([(|)])/);
    die "Empty category: $cat\n" if ($contents =~ /^$/);
    my $tmp = [];
    push @$tmp, split / +/, $contents;
    $cats{$cat} = $tmp;
  } elsif (/ > /) {
    my @rule = split / > /;
    $rule[0] ne "" ? my @avant = split (/\s+/, $rule[0]) : die "No avant\n";
    my @apres = split (/\s+/, $rule[1]) if defined $rule[1];
    (my $avant, $total) = parseAvant (@avant);
    my $apres = parseApres ($total, $ruleNo, @apres);
    push @rulesAv, $avant;
    push @rulesAp, $apres;
    $ruleNo++; # This is intentional; it increments only for sound changes.
  }
}
close RULES;

open WORDS, "<words.txt" or die "words.txt not found";
while (<WORDS>) {
  chomp;
  print my $word = $_;
  my @index = (0);
  for (my $i = 0; $i <= $#rulesAv; $i++) {
    my $old = $word;
    my $av = $rulesAv[$i];
    my $ap = $rulesAp[$i];
    @index = regindex ($word, $av, $index[$#index]);
    unless (0) {                              #TODO: unless the program should wait
      my $offset = 0;
      while (@index > 0) {
        ($word, $offset) = replace ($i, $word, $offset, shift @index, shift @index, $av, $ap);
      }
      print " > $word";# if ($old ne $word);  #TODO: option to show every step or not
      @index = (0);
      shift @map; shift @map; shift @map;
    }
  }
  say "";
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
      $avant .= "($_)";
    }
  }
  return ($avant, $counter);
}

sub parseApres {
  my $total = shift;
  my $ruleNo = shift;
  my $apres;
  my $currMapIndex = 0;
  foreach (@_) {
    if (/^<([^>]+)>/) { # was /^<([^>]+)>$/
      #die "Use of category in apres: $1\n";
      die "Uninitialized category: <$1>\n" unless (exists $cats{$1});
      die "Unspecified backreference for category <$1>\n" unless (/^<($1)>\$0*(\d+)$/);
      die "Invalid backreference: \$$2\n" unless ($2 ne "0" && $2 <= $total);
      push @map, ($ruleNo, $1, $2);
 #$apres .= "($ruleNo,$1,$2)";
      $apres .= "\$currMap[$currMapIndex]";
      $currMapIndex++;
    } elsif (/^\$0*(\d+)$/) {
      $1 ne "0" && $1 <= $total ? $apres .= "\$" . $1 : die "Invalid backreference: \$$1\n";
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

sub regindex {say "";
  my $word = shift;
  my $regex = shift;
  my $index = shift; # always 0 for now
  my @indices;
  for (my $i = $index; $i < length $word; $i++) {
    if ($word =~ /(?:^.{$i})$regex/) {
      push @indices, ($i);
      push @indices, (length ($&) - $i);
    }
  }
  return @indices;
}

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub replace {
  my $ruleNo = shift;
  my $word = shift;
  my $os = shift;
  my $pos = shift() + $os;
  my $len = shift;
  my $av = shift;
  my $ap = shift;
  my $pre = substr ($word, 0, $pos);
  my $post = substr ($word, $pos);
  
 #say "RPA: $ruleNo, $post, $av";
  stockCurrMap($ruleNo, $post, $av);
  
  $av =~ /$av/;
  my $count = my $okay = 1;
  REF: while (1) {
    eval "\$okay = defined \$$count";
    eval "\$okay ? push \@r, \$$count : last REF";
    $count++;
  }
  say "r:$_" for (@r);
  
  eval "\$post =~ s/.\{$len\}/$ap/";
  $os += length ("$pre$post") - length ($word);
  @currMap = ();
  return ("$pre$post", $os);
}

sub stockCurrMap {                      #TODO: (somewhere) check that mapped cats have same length
 #say "SCM: ", @_, ":", @map;
  my @localMap = @map;
  while (@localMap > 0 && $localMap[0] == $_[0]) {
    shift @localMap;
    my $post = $_[1];
    my $av = $_[2];
    my $apCat = shift @localMap;
    my $num = shift @localMap;
    my $foo;
    eval "\$foo = \$$num if (\$post =~ /$av/)";
    my $posAv = positionAvant ($foo, $num, $av);
    my $correspondingAp = @{$cats{$apCat}}[$posAv];
    push @currMap, $correspondingAp;
  }
}

sub position {
  my $x = shift;
  return -1 unless (defined $x);
  my $name = shift;
  foreach (0 .. $#{$cats{$name}}) {
    return $_ if (@{$cats{$name}}[$_] eq $x);
  }
  return -1;
}

sub positionAvant {
  my $x = shift;
  my $num = shift;
  my $parsedCat = shift;
  $parsedCat =~ s/^\(//;
  $parsedCat =~ s/\)$//;
  my @arr = split "\\)\\(", $parsedCat;
  @arr = split "\\|", $arr[$num - 1];
  my $avantCatIndex = -1;
  ACI: foreach (0 .. $#arr) {
    if ($arr[$_] eq $x) {
      $avantCatIndex = $_;
      last ACI;
    }
  }
  return $avantCatIndex;
}