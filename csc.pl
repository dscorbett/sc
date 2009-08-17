#!/bin/perl
# A tool for converting SCA's rule files into SC's

use feature "say";
use strict;
use warnings;

# TODO:
# backquotes and double backquotes

my $sc = "spanish.sc";
$sc =~ /(.*)\.sc/;
my $txt = "$1.txt";
my $cats = "";
my $syms = "";

open SC, "<$sc" or die "$sc does not exist\n";
while (<SC>) {
  chomp;
  $_ = trim ($_);
  my $line = "";
  ($_, my $endline) = split /!|^#/, $_, 2;
  $_ .= "";
  if (/^END$/) {
    $line = "END";
  } elsif (/^NOSKIP$/) {
    $line = "NOSKIP";
  } elsif (/^SKIP\s+(if|unless)\s+(\S+)$/) {
    $line = "SKIP";
    $line .= " $1 $2" if (defined $1 && defined $2);
  } elsif (/^Include\s*=\s*(.*)$/) {
    $line = "!$_";
  } elsif (/^dialects\s*=\s*(.*)$/) {
    $line = "[$1]";
  } elsif (/^conditions\s*=\s*(.*)$/) {
    $line = "COND $1";
  } elsif (/(.*)\s*=\s*(.*)/) {
    if ($syms =~ /\b$1\b/) {
      $line = "! not allowed; \"$1\" has previously been used as a symbol.";
    } else {
      $line .= "$1 =";
      $cats .= "$1 ";
      foreach my $value (split /\s+/, $2) {
        if ($cats =~ /\b$value\b/) {
          $line .= " <$value>";
        } else {
          foreach (split //, $value) {
            if ($_ ne "0") {
              $line .= " $_";
              $syms .= "$_ ";
            }
          }
        }
      }
    }
  } elsif (/(\S+\s+){3,4}\S+/) {
    my @rule = split /\s+/, $_;
    my @env = split /_/, $rule[3];
    
    my $dialects = "";
    $rule[0] =~ s/\*//;
    $rule[0] =~ s/\.//;
    $dialects = "[$rule[0]]" unless ($rule[0] eq "");
    
    my $before;
    my $binding = 0;
    my @avant = ();
    my @before = split //, $rule[1];
    while ($#before + 1) {
      $before = "";
      my $cur = shift @before;
      if ($cur =~ /0/) {
      } elsif ($cur =~ /</) {
        my $brackets = 1;
        $before .= $cur;
        while ($#before + 1) {
          my $cur2 = shift @before;
          $before .= $cur2;
          $brackets++ if ($cur2 =~ /</);
          $brackets-- if ($cur2 =~ />/);
          last if ($brackets == 0);
        }
      } elsif ($cur =~ /[+?*]/) {
        $before .= $cur;
        $binding = 1;
      } elsif ($cur =~ /\|/) {
        $before .= $cur;
        $binding = 2;
      } else {
        $before .= $cur;
      }
      push @avant, $before if ($binding <= 0);
      $avant[-1] .= $before if ($binding > 0);
      $binding--;
    }
    
    my $after;
    $binding = 0;
    my @apres = ();
    my @after = split //, $rule[2];
    while ($#after + 1) {
      $after = "";
      my $cur = shift @after;
      if ($cur =~ /0/) {
      } elsif ($cur =~ /</) {
        my $brackets = 1;
        $before .= $cur;
        while ($#before + 1) {
          my $cur2 = shift @before;
          $before .= $cur2;
          $brackets++ if ($cur2 =~ /</);
          $brackets-- if ($cur2 =~ />/);
          last if ($brackets == 0);
        }
      } elsif ($cur =~ /[+?*]/) {
        $before .= $cur;
        $binding = 1;
      } elsif ($cur =~ /\|/) {
        $before .= $cur;
        $binding = 2;
      } else {
        $before .= $cur;
      }
      push @avant, $before if ($binding <= 0);
      $avant[-1] .= $before if ($binding > 0);
      $binding--;
    }
    
    $line = "$dialects " . join (",", @avant);
  }
  print "$line";
  print "!$endline" if (defined $endline);
  say "";
}

sub trim {
  my $string = shift;
  $string =~ s/^\s+//;
  $string =~ s/\s+$//;
  return $string;
}

sub catref {
  (my $cat, my $addenda) = split /[+-]/, shift;
  
  if (defined $cat) {
    if ($cat =~ /^<(.*),(.*)>$/) {
      $cat = "<$1><$2>";
    } elsif ($cat =~ /^\^/) {
      $cat = "^<$cat>";
    } else {
      $cat = "<$cat>";
    }
  } else {
    $cat = "";
  }
  return $cat . join "|", split //, $addenda;
}