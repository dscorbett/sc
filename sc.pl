#!/usr/bin/perl
# Sound Changer
# A phonological shift simulator, like Geoff Eddy's SCA and Zompist's sounds

# Copyright (C) 2009 David Corbett
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# (I don't see the point of copying the full GPL text so if you really care go look it up.)

# Based on sc4.1.pl, with:
# backreferences to backreferences
# escaped slashes
# acceptable Unicode support
# multiple words files
# HTML code names
# custom code names
# Unicode decomposition
# properly-escaped pattern-matching characters in dialects
# multiple consecutive visible comments

######## SET-UP ########

use charnames ();
use encoding "UTF-8";
#use feature "say";
use strict;
use utf8;
use warnings;
use Encode;
use Unicode::Normalize;

my $UTF8 = ":utf8";

######## DISPLAY CODES ########

my $wysiwyg = " !\"#\$%&'()*+,-./0123456789:;<=>?\@ABCDEFGHIJKLMNOPQRSTUVWXYZ^_`abcdefghijklmnopqrstuvwxyz{|}~\n\t\[\]\\";

my %html = (
# "0022" => "&quot;",
# "0026" => "&amp;",
# "0027" => "&apos;",
# "003C" => "&lt;",
# "003E" => "&gt;",
  "00A0" => "&nbsp;",
  "00A1" => "&iexcl;",
  "00A2" => "&cent;",
  "00A3" => "&pound;",
  "00A4" => "&curren;",
  "00A5" => "&yen;",
# "00A6" => "&brvbar;",
  "00A7" => "&sect;",
  "00A8" => "&uml;",
  "00A9" => "&copy;",
  "00AA" => "&ordf;",
  "00AB" => "&laquo;",
  "00AC" => "&not;",
  "00AD" => "&shy;",
  "00AE" => "&reg;",
  "00AF" => "&macr;",
  "00B0" => "&deg;",
  "00B1" => "&plusmn;",
  "00B2" => "&sup2;",
  "00B3" => "&sup3;",
  "00B4" => "&acute;",
  "00B5" => "&micro;",
  "00B6" => "&para;",
  "00B7" => "&middot;",
  "00B8" => "&cedil;",
  "00B9" => "&sup1;",
  "00BA" => "&ordm;",
  "00BB" => "&raquo;",
  "00BC" => "&frac14;",
  "00BD" => "&frac12;",
  "00BE" => "&frac34;",
  "00BF" => "&iquest;",
  "00C0" => "&Agrave;",
  "00C1" => "&Aacute;",
  "00C2" => "&Acirc;",
  "00C3" => "&Atilde;",
  "00C4" => "&Auml;",
  "00C5" => "&Aring;",
  "00C6" => "&AElig;",
  "00C7" => "&Ccedil;",
  "00C8" => "&Egrave;",
  "00C9" => "&Eacute;",
  "00CA" => "&Ecirc;",
  "00CB" => "&Euml;",
  "00CC" => "&Igrave;",
  "00CD" => "&Iacute;",
  "00CE" => "&Icirc;",
  "00CF" => "&Iuml;",
  "00D0" => "&ETH;",
  "00D1" => "&Ntilde;",
  "00D2" => "&Ograve;",
  "00D3" => "&Oacute;",
  "00D4" => "&Ocirc;",
  "00D5" => "&Otilde;",
  "00D6" => "&Ouml;",
  "00D7" => "&times;",
  "00D8" => "&Oslash;",
  "00D9" => "&Ugrave;",
  "00DA" => "&Uacute;",
  "00DB" => "&Ucirc;",
  "00DC" => "&Uuml;",
  "00DD" => "&Yacute;",
  "00DE" => "&THORN;",
  "00DF" => "&szlig;",
  "00E0" => "&agrave;",
  "00E1" => "&aacute;",
  "00E2" => "&acirc;",
  "00E3" => "&atilde;",
  "00E4" => "&auml;",
  "00E5" => "&aring;",
  "00E6" => "&aelig;",
  "00E7" => "&ccedil;",
  "00E8" => "&egrave;",
  "00E9" => "&eacute;",
  "00EA" => "&ecirc;",
  "00EB" => "&euml;",
  "00EC" => "&igrave;",
  "00ED" => "&iacute;",
  "00EE" => "&icirc;",
  "00EF" => "&iuml;",
  "00F0" => "&eth;",
  "00F1" => "&ntilde;",
  "00F2" => "&ograve;",
  "00F3" => "&oacute;",
  "00F4" => "&ocirc;",
  "00F5" => "&otilde;",
  "00F6" => "&ouml;",
  "00F7" => "&divide;",
  "00F8" => "&oslash;",
  "00F9" => "&ugrave;",
  "00FA" => "&uacute;",
  "00FB" => "&ucirc;",
  "00FC" => "&uuml;",
  "00FD" => "&yacute;",
  "00FE" => "&thorn;",
  "00FF" => "&yuml;",
  "0152" => "&OElig;",
  "0153" => "&oelig;",
  "0160" => "&Scaron;",
  "0161" => "&scaron;",
  "0178" => "&Yuml;",
  "0192" => "&fnof;",
  "02C6" => "&circ;",
  "02DC" => "&tilde;",
  "0391" => "&Alpha;",
  "0392" => "&Beta;",
  "0393" => "&Gamma;",
  "0394" => "&Delta;",
  "0395" => "&Epsilon;",
  "0396" => "&Zeta;",
  "0397" => "&Eta;",
  "0398" => "&Theta;",
  "0399" => "&Iota;",
  "039A" => "&Kappa;",
  "039B" => "&Lambda;",
  "039C" => "&Mu;",
  "039D" => "&Nu;",
  "039E" => "&Xi;",
  "039F" => "&Omicron;",
  "03A0" => "&Pi;",
  "03A1" => "&Rho;",
  "03A3" => "&Sigma;",
  "03A4" => "&Tau;",
  "03A5" => "&Upsilon;",
  "03A6" => "&Phi;",
  "03A7" => "&Chi;",
  "03A8" => "&Psi;",
  "03A9" => "&Omega;",
  "03B1" => "&alpha;",
  "03B2" => "&beta;",
  "03B3" => "&gamma;",
  "03B4" => "&delta;",
  "03B5" => "&epsilon;",
  "03B6" => "&zeta;",
  "03B7" => "&eta;",
  "03B8" => "&theta;",
  "03B9" => "&iota;",
  "03BA" => "&kappa;",
  "03BB" => "&lambda;",
  "03BC" => "&mu;",
  "03BD" => "&nu;",
  "03BE" => "&xi;",
  "03BF" => "&omicron;",
  "03C0" => "&pi;",
  "03C1" => "&rho;",
  "03C2" => "&sigmaf;",
  "03C3" => "&sigma;",
  "03C4" => "&tau;",
  "03C5" => "&upsilon;",
  "03C6" => "&phi;",
  "03C7" => "&chi;",
  "03C8" => "&psi;",
  "03C9" => "&omega;",
  "03D1" => "&thetasym;",
  "03D2" => "&upsih;",
  "03D6" => "&piv;",
  "2002" => "&ensp;",
  "2003" => "&emsp;",
  "2009" => "&thinsp;",
  "200C" => "&zwnj;",
  "200D" => "&zwj;",
  "200E" => "&lrm;",
  "200F" => "&rlm;",
  "2013" => "&ndash;",
  "2014" => "&mdash;",
  "2018" => "&lsquo;",
  "2019" => "&rsquo;",
  "201A" => "&sbquo;",
  "201C" => "&ldquo;",
  "201D" => "&rdquo;",
  "201E" => "&bdquo;",
  "2020" => "&dagger;",
  "2021" => "&Dagger;",
  "2022" => "&bull;",
  "2026" => "&hellip;",
  "2030" => "&permil;",
  "2032" => "&prime;",
  "2033" => "&Prime;",
  "2039" => "&lsaquo;",
  "203A" => "&rsaquo;",
  "203E" => "&oline;",
  "2044" => "&frasl;",
  "20AC" => "&euro;",
  "2111" => "&image;",
  "2118" => "&weierp;",
  "211C" => "&real;",
  "2122" => "&trade;",
  "2135" => "&alefsym;",
  "2190" => "&larr;",
  "2191" => "&uarr;",
  "2192" => "&rarr;",
  "2193" => "&darr;",
  "2194" => "&harr;",
  "21B5" => "&crarr;",
  "21D0" => "&lArr;",
  "21D1" => "&uArr;",
  "21D2" => "&rArr;",
  "21D3" => "&dArr;",
  "21D4" => "&hArr;",
  "2200" => "&forall;",
  "2202" => "&part;",
  "2203" => "&exist;",
  "2205" => "&empty;",
  "2207" => "&nabla;",
  "2208" => "&isin;",
  "2209" => "&notin;",
  "220B" => "&ni;",
  "220F" => "&prod;",
  "2211" => "&sum;",
  "2212" => "&minus;",
  "2217" => "&lowast;",
  "221A" => "&radic;",
  "221D" => "&prop;",
  "221E" => "&infin;",
  "2220" => "&ang;",
  "2227" => "&and;",
  "2228" => "&or;",
  "2229" => "&cap;",
  "222A" => "&cup;",
  "222B" => "&int;",
  "2234" => "&there4;",
  "223C" => "&sim;",
  "2245" => "&cong;",
  "2248" => "&asymp;",
  "2260" => "&ne;",
  "2261" => "&equiv;",
  "2264" => "&le;",
  "2265" => "&ge;",
  "2282" => "&sub;",
  "2283" => "&sup;",
  "2284" => "&nsub;",
  "2286" => "&sube;",
  "2287" => "&supe;",
  "2295" => "&oplus;",
  "2297" => "&otimes;",
  "22A5" => "&perp;",
  "22C5" => "&sdot;",
  "2308" => "&lceil;",
  "2309" => "&rceil;",
  "230A" => "&lfloor;",
  "230B" => "&rfloor;",
  "2329" => "&lang;",
  "232A" => "&rang;",
  "25CA" => "&loz;",
  "2660" => "&spades;",
  "2663" => "&clubs;",
  "2665" => "&hearts;",
  "2666" => "&diams;",
);

######## COMMAND-LINE ARGUMENTS ########

my %cond;
my $reqDial = "";
my $edit = 0;
my $fields = ",";
my $colonThreshold = 0;
my $html = 0;
my $limit = my $maxLimit = 1000; 
my $mode = 3; # 0 = final; 1 = original and final; 2 = after each non-persistant rule; 3 = after each rule
my $nfkd = 0;
my $output;
my $rules = "rules.txt";
my $separator = ",";
my $notAll = 0;
my $unicode = 0;
my $exact = 0;
my @words;

foreach (@ARGV) {
  $_ = decode ("cp437", $_);
  (/^-(?:c|cond)=(.+)$/i) ? parseCond (uc $1) :
  (/^-(?:d|dialects)=(.+)$/i) ? $reqDial = $1 :
  (/^-(?:e|edit)$/i) ? $edit = 1 :
  (/^-(?:f|fields)$/i) ? parseFields (1) :
  (/^-(?:f|fields)=(.+)$/i) ? parseFields ($1) :
  (/^-(?:hl|hlevel)=(\d+)$/i) ? $colonThreshold = $1 :
  (/^-(h|help)$/i) ? record ("SC © 2009 by David Corbett. For more information read readme_sc5.txt.\n\n") :
  (/^-html$/i) ? $html = 1 :
  (/^-(?:l|limit)=(\d+)$/i) ? $limit = $maxLimit = $1 :
  (/^-(?:m|mode)=(\d+)$/i) ? $mode = $1 :
  (/^-(n|nfkd)$/i) ? $nfkd = 1 :
  (/^-(?:o|output)$/i) ? $output = "" :
  (/^-(?:o|output)=(.+)$/i) ? $output = $1 :
  (/^-(?:r|rules)=(.+)$/i) ? $rules = $1 :
  (/^-(?:sep|separator)$/i) ? $separator = "\t" :
  (/^-(?:sep|separator)=(.+)$/i) ? $separator = $1 :
  (/^-(s|some)$/i) ? $notAll = 1 :
  (/^-(?:u|unicode)$/i) ? $unicode = 1 :
  (/^-(?:x|exact)=(\d+)$/i) ? $exact = $1 :
  (/^-(?:w|words)=(.+)$/) ? parseWordsFile ($1) :
  push @words, $_;
}

if ($limit == 0) {
  $limit = $maxLimit = .5;
}

if (defined $output) {
  $output = "output_$rules" if ($output eq "");
  open OUTPUT, ">$UTF8", "$output" or die "$output not accessible\n";
  $output = *OUTPUT;
}

parseWordsFile ("words.txt") unless ($#words + 1);

unless ($fields eq ",") {
  my @newWords = ();
  foreach my $w (0 .. $#words) {
    my @line = split $separator, $words[$w];
    foreach (0 .. $#line) {
      my $plusOne = $_ + 1;
      push @newWords, $line[$_] if ($fields =~ ",$plusOne,");
    }
  }
  push @words, @newWords if ($#newWords + 1);
}

######## COMMAND-LINE ARGUMENT SUBROUTINES ########

sub parseCond {
  $cond{$_} = "" foreach (split ",", shift);
}

sub parseWordsFile {
  open WORDS, "<$UTF8", $_[0] or die "$_[0] not found\n";
  chomp (my @newWords = <WORDS>);
  close WORDS;
  $newWords[0] =~ s/^.//; # destroy the byte-order mark
  push @words, @newWords;
}

sub parseFields {
  my @csv = split ",", shift;
  my $ret = "";
  foreach (@csv) {
    my @ranges = split "-";
    foreach (@ranges) {
      unless (/^\d+$/) {
        warn "Non-digits in numeric range in -fields\n";
        return;
      }
    }
    if ($#ranges != 0 && $ranges[0] >= $ranges[-1]) {
      warn "Minimum not less than maximum in -fields range\n";
      return;
    }
    foreach ($ranges[0] .. $ranges[-1]) {
      $ret .= "$_,";
    }
  }
  $fields .= $ret;
}

######## VARIABLES ########

my %cats;
my @tentAbsAvant;
my @absAvant;
my @tentAbsApres;
my @absApres;
my $scNum = 0;
my $dialect = "";
my $tentDialects;
my @dialects;
my $tentDialectsPersist;
my @dialectsPersist;
my $tentPersist = "";
my $persist = ",";
my $tentRepeat = "";
my $repeat = ",";
my $skip = 0; # 0 = noskip; 1 = skip
my @colon;
my %name;
my %include;

######## RULES ########

my $lvl = -1;
rules ($rules, $lvl);

sub rules {
  my $rules = shift;
  my $lvl = 1 + shift;
  
  die "Error: Infinite recursion ($rules would include itself)\n" if (defined $include{"$rules"});
  $include{"$rules"} = $lvl;
  
  eval "open RULES$lvl, \"<$UTF8\", \"\$rules\" or die";
  die "$rules not found ($lvl level(s) deep)\n" if (defined $@ && $@ ne "");
  my $rulesRef;
  eval "\$rulesRef = \\\*RULES$lvl";
  chomp (my @rulesRef = <$rulesRef>);
  $rulesRef[0] =~ s/^.//; # Begone, FEFF!
  RULE: foreach (@rulesRef) { # while (<$rulesRef>) {
    # SET-UP
    next if (/^\s*($|!)/);
  # chomp;
    ($_) = split /!/, $_;
    $_ = trim ($_);
    
    # RESETTING
    @tentAbsAvant = ();
    @tentAbsApres = ();
    
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
    
    if (/\s+>\s+/) {
      my @rule = split /\s+>\s+/;
      if (defined $rule[0]) {
        my @avant = split /\s+/, $rule[0];
        unless (defined $avant[0]) {
          warn "Rule ", $scNum + 1, " has no original form\n";
        } else {
          if ($avant[0] =~ /\[(.*)\]/) {
            $tentDialects = $1;
            shift @avant;
          } else {
            $tentDialects = "";
          }
          
          foreach (@avant) {
            # COMPLEMENTS
            my $complement = "";
            my $complement2 = "";
            $complement = "(?!" if (/^\^/);
            $complement2 = ")" if (/^\^/);
            $_ =~ s/^\^//;
            
            # QUANTIFIERS AND GREED
            my $min = 1;
            my $max = 1;
            my $greed = "";
            if (/(?:(?!\\).)\*(\?|)$/) {
              $min = 0;
              $max = "";
              $greed = "?" if ($1 eq "?");
            } elsif (/(?:(?!\\).)\+(\?|)$/) {
              $min = 1;
              $max = "";
              $greed = "?" if ($1 eq "?");
            } elsif (/(?:(?!\\).)\{(.*)\}(\?|)$/) {
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
            } elsif (/(?:(?!\\).)\?(\?|)$/) {
              $min = 0;
              $max = 1;
              $greed = "?" if ($1 eq "?");
            }
            if ($max ne "" && $min > $max) {
              my $tmp = $min;
              $min = $max;
              $max = $tmp;
            }
            $_ =~ s/(?=(?!\\).)(\{(.*)\}|\*|\+|\?)(\?|)$//;
            $_ =~ s/(?=[^\\]|^)(\{|\}|\*|\\|\?|\(|\)|\\)/\\$1/;
            
            # THE MAIN PART OF THE REGEX
            $_ =~ s/>\|</>+</g; # change | to + between categories
            $_ =~ s/#/\\b/g; # change # to \b
            
            my @units = split /(?=\+|-)/, $_;
            my @newUnits;
#say "units: ", join ",", @units;
            foreach my $unit (@units) {
              next if ($unit =~ /^-/);
              $unit =~ s/\+//;
              my @subunits = split /\|/, $unit;
              my @newSubunits;
#say "subunits: ", join ",", @subunits;
              foreach my $subunit (@subunits) {
                my @chars = split //, $subunit;
                my @quarks = ("");
                my $angleBrackets = 0;
                my $bracketed = 0;
                my $dollarSign = 0;
                my $backreferenced = 0;
                while ($#chars + 1) {
                  if ($chars[0] eq "<") {
                    $angleBrackets++;
                    $bracketed = -1;
                  } elsif ($chars[0] eq ">") {
                    $angleBrackets--;
                    $bracketed = 1 if ($angleBrackets == 0);
                  } else {
                    $bracketed = 0;
                  }
                  if ($chars[0] eq "\$" && !$bracketed) {
                    $dollarSign = 2;
                  }
                  if ($dollarSign == 1 && $chars[0] !~ /^\d/) {
                    $backreferenced = -1;
                    $dollarSign = 0;
                  }
                  push @quarks, "" if (($bracketed == -1 && $quarks[-1] ne "") || ($dollarSign == 2 && $quarks[-1] ne "") || $backreferenced == -1);
                  $quarks[-1] .= $chars[0];
                  $backreferenced = 0;
                  $dollarSign = 1 if ($dollarSign == 2);
                  push @quarks, "" if ($bracketed == 1);
                  shift @chars;
                }
                pop @quarks if ($quarks[-1] eq "");
#say "quarks: ", join ",", @quarks;
                
                foreach my $q (0 .. $#quarks) {
                  if ($quarks[$q] =~ /<(.*?)>/) {
                    $quarks[$q] = catContents ($1);
                  } elsif ($quarks[$q] =~ /^\$0*(\d+)$/) {
                    if ($1 > $#tentAbsAvant + 1) {
                      unless ($#tentAbsAvant == -1) {
                        warn "Backreference value greater than \$", $#tentAbsAvant + 1, " found in rule ", $scNum + 1, "\n";
                      } else {
                        warn "Backreference found as first index of rule ", $scNum + 1, "\n";
                      }
                      next RULE;
                    } elsif ($1 == 0) {
                      warn "Backreference \$0 is meaningless because indexes start at 1\n";
                      next RULE;
                    } else {
                      $quarks[$q] = "\\$1";
                    }
                  }
                }
                
                while ($#quarks > 0) {
                  my @one = split /\|/, shift @quarks;
                  my @two = split /\|/, shift @quarks;
                  my @tmp = ();
                  foreach my $one (@one) {
                    foreach my $two (@two) {
                      push @tmp, "$one$two";
                    }
                  }
                  unshift @quarks, join "|", @tmp;
#say "quark: ", $quarks[0];
                }
                
                push @newSubunits, $quarks[0];
#say "newSubunits: ", join ",", @newSubunits;
              }
              push @newUnits, join "|", @newSubunits;
#say "newUnits: ", join ",", @newUnits;
            }
            
            my $positive = "|" . join "|", @newUnits;
#say "positive: $positive";
            
            @newUnits = ();
            foreach my $unit (@units) {
              next unless ($unit =~ /^-/);
              $unit =~ s/-//;
              my @subunits = split /\|/, $unit;
              my @newSubunits;
#say "-subunits: ", join ",", @subunits;
              foreach my $subunit (@subunits) {
                my @chars = split //, $subunit;
                my @quarks = ("");
                my $angleBrackets = 0;
                my $bracketed = 0;
                my $dollarSign = 0;
                my $backreferenced = 0;
                while ($#chars + 1) {
                  if ($chars[0] eq "<") {
                    $angleBrackets++;
                    $bracketed = -1;
                  } elsif ($chars[0] eq ">") {
                    $angleBrackets--;
                    $bracketed = 1 if ($angleBrackets == 0);
                  } else {
                    $bracketed = 0;
                  }
                  if ($chars[0] eq "\$" && !$bracketed) {
                    $dollarSign = 2;
                  }
                  if ($dollarSign == 1 && $chars[0] !~ /^\d/) {
                    $backreferenced = -1;
                    $dollarSign = 0;
                  }
                  push @quarks, "" if (($bracketed == -1 && $quarks[-1] ne "") || ($dollarSign == 2 && $quarks[-1] ne "") || $backreferenced == -1);
                  $quarks[-1] .= $chars[0];
                  $backreferenced = 0;
                  $dollarSign = 1 if ($dollarSign == 2);
                  push @quarks, "" if ($bracketed == 1);
                  shift @chars;
                }
                #shift @quarks if ($quarks[0] eq "");
                pop @quarks if ($quarks[-1] eq "");
#say "-quarks: ", join ",", @quarks;
                
                foreach my $q (0 .. $#quarks) {
                  if ($quarks[$q] =~ /<(.*?)>/) {
                    $quarks[$q] = catContents ($1);
                  } elsif ($quarks[$q] =~ /^\$0*(\d+)$/) {
                    if ($1 > $#tentAbsAvant + 1) {
                      warn "Backreference value greater than \$", $#tentAbsAvant + 1, " found in rule ", $scNum + 1, "\n";
                      next RULE;
                    } elsif ($1 == 0) {
                      warn "Meaningless backreference \$0 found in rule ", $scNum + 1, " (indexes start at 1)\n";
                      next RULE;
                    } else {
                      $quarks[$q] = "\\$1";
                    }
                  }
                }
                
                while ($#quarks > 0) {
                  my @one = split /\|/, shift @quarks;
                  my @two = split /\|/, shift @quarks;
                  my @tmp = ();
                  foreach my $one (@one) {
                    foreach my $two (@two) {
                      push @tmp, "$one$two";
                    }
                  }
                  unshift @quarks, join "|", @tmp;
#say "-quark: ", $quarks[0];
                }
                
                push @newSubunits, $quarks[0];
#say "-newSubunits: ", join ",", @newSubunits;
              }
              push @newUnits, join "|", @newSubunits;
#say "-newUnits: ", join ",", @newUnits;
            }
            
            $positive .= "|";
            my @negative = split "\\|", join "|", @newUnits;
#say "negative: ", join ",", @negative;
            foreach my $negative (@negative) {
              $negative =~ s/\\/\\\\/g;
              $negative =~ s/\\\\\\/\\/g;
              $positive =~ s/\|$negative\|/\|/g;
            }
            $positive =~ s/\|$//;
            $positive =~ s/^\|//;
            
            if (!defined $positive || $positive eq "") {
              warn "Useless empty string in the first half of rule ", $scNum + 1, "\n";
              next RULE;
            }
#say "POSITIVE: $positive";
            $positive =~ s/\|/\)\(\?\!/g unless ($complement eq ""); # | -> )(?! if complementing
            push @tentAbsAvant, "($complement$positive$complement2){$min,$max}$greed";
          }
        }
        next RULE if ($#tentAbsAvant == -1);
        
        my @apres = ("");
        @apres = split (/\s+/, $rule[1]) if defined $rule[1];
        if ($apres[-1] =~ /\[(.*)\]/) {
          my $flags = $1;
          if ($flags =~ /P/i) {
            $tentPersist .= "$scNum,";
          }
          if ($flags =~ /R/i) {
            $tentRepeat .= "$scNum,";
          }
          pop @apres;
        }
        if ($apres[0] eq "") {
          # The apres can be blank. It's okay.
        } else {
          foreach (@apres) {
            # SUFFICES
            my $suffix = -1;
            if (/\$0*(\d+)$/) {
              $suffix = $1;
            }
            $_ =~ s/\$(\d+)$//;
            if ($suffix > $#tentAbsAvant + 1) {
              warn "Backreference value greater than \$", $#tentAbsAvant + 1, " found in rule ", $scNum + 1, "\n";
              next RULE;
            } elsif ($suffix == 0) {
              warn "Meaningless backreference \$0 found in rule ", $scNum + 1, " (indexes start at 1)\n";
              next RULE;
            }
            
            $_ =~ s/(?=(?!\\).)(\{(.*)\}|\*|\+|\?)(\?|)$//;
            $_ =~ s/(?=[^\\]|^)(\{|\}|\*|\\|\?|\(|\)|\\)/\\$1/;
            
            # THE MAIN PART OF THE REGEX
            $_ =~ s/>\|</>+</g; # change | to + between categories
            
            my @units = split /(?=\+|-)/, $_;
            my @newUnits;
#say "units: ", join ",", @units;
            foreach my $unit (@units) {
              next if ($unit =~ /^-/);
              $unit =~ s/\+//;
              my @subunits = split /\|/, $unit;
              my @newSubunits;
#say "subunits: ", join ",", @subunits;
              foreach my $subunit (@subunits) {
                $subunit = "" unless (defined $subunit);
                my @chars = split //, $subunit;
                my @quarks = ("");
                my $angleBrackets = 0;
                my $bracketed = 0;
                my $dollarSign = 0;
                my $backreferenced = 0;
                while ($#chars + 1) {
                  if ($chars[0] eq "<") {
                    $angleBrackets++;
                    $bracketed = -1;
                  } elsif ($chars[0] eq ">") {
                    $angleBrackets--;
                    $bracketed = 1 if ($angleBrackets == 0);
                  } else {
                    $bracketed = 0;
                  }
                  if ($chars[0] eq "\$" && !$bracketed) {
                    $dollarSign = 2;
                  }
                  if ($dollarSign == 1 && $chars[0] !~ /^\d/) {
                    $backreferenced = -1;
                    $dollarSign = 0;
                  }
                  push @quarks, "" if (($bracketed == -1 && $quarks[-1] ne "") || ($dollarSign == 2 && $quarks[-1] ne "") || $backreferenced == -1);
                  $quarks[-1] .= $chars[0];
                  $backreferenced = 0;
                  $dollarSign = 1 if ($dollarSign == 2);
                  push @quarks, "" if ($bracketed == 1);
                  shift @chars;
                }
                pop @quarks if ($quarks[-1] eq "");
#say "quarks: ", join ",", @quarks;
                
                foreach my $q (0 .. $#quarks) {
                  if ($quarks[$q] =~ /<(.*?)>/) {
                    $quarks[$q] = catContents ($1);
                  } elsif ($quarks[$q] =~ /^\$0*(\d+)$/) {
                    if ($1 > $#tentAbsAvant + 1) {
                      unless ($#tentAbsAvant == -1) {
                        warn "Backreference value greater than \$", $#tentAbsAvant + 1, " found in rule ", $scNum + 1, "\n";
                      } else {
                        warn "Meaningless backreference \$0 found in rule ", $scNum + 1, " (indexes start at 1)\n";
                      }
                      next RULE;
                    } elsif ($1 == 0) {
                      warn "Meaningless backreference \$0 found in rule ", $scNum + 1, " (indexes start at 1)\n";
                      next RULE;
                    } else {
                      $quarks[$q] = "\$theAvant[$1]";
                    }
                  }
                }
                
                while ($#quarks > 0) {
                  my @one = split /\|/, shift @quarks;
                  my @two = split /\|/, shift @quarks;
                  my @tmp = ();
                  foreach my $one (@one) {
                    foreach my $two (@two) {
                      push @tmp, "$one$two";
                    }
                  }
                  unshift @quarks, join "|", @tmp;
                  $quarks[0] = "" unless (defined $quarks[0]);
#say "quark: ", $quarks[0];
                }
                
                push @newSubunits, $quarks[0];
                foreach (0 .. $#newSubunits) {
                  $newSubunits[$_] = "" unless (defined $newSubunits[$_]);
                }
#say "newSubunits: ", join ",", @newSubunits;
              }
              push @newUnits, join "|", @newSubunits;
#say "newUnits: ", join ",", @newUnits;
            }
            
            my $positive = "|" . join "|", @newUnits;
#say "positive: $positive";
            
            @newUnits = ();
            foreach my $unit (@units) {
              next unless ($unit =~ /^-/);
              $unit =~ s/-//;
              my @subunits = split /\|/, $unit;
              my @newSubunits;
#say "-subunits: ", join ",", @subunits;
              foreach my $subunit (@subunits) {
                my @chars = split //, $subunit;
                my @quarks = ("");
                my $angleBrackets = 0;
                my $bracketed = 0;
                my $dollarSign = 0;
                my $backreferenced = 0;
                while ($#chars + 1) {
                  if ($chars[0] eq "<") {
                    $angleBrackets++;
                    $bracketed = -1;
                  } elsif ($chars[0] eq ">") {
                    $angleBrackets--;
                    $bracketed = 1 if ($angleBrackets == 0);
                  } else {
                    $bracketed = 0;
                  }
                  if ($chars[0] eq "\$" && !$bracketed) {
                    $dollarSign = 2;
                  }
                  if ($dollarSign == 1 && $chars[0] !~ /^\d/) {
                    $backreferenced = -1;
                    $dollarSign = 0;
                  }
                  push @quarks, "" if (($bracketed == -1 && $quarks[-1] ne "") || ($dollarSign == 2 && $quarks[-1] ne "") || $backreferenced == -1);
                  $quarks[-1] .= $chars[0];
                  $backreferenced = 0;
                  $dollarSign = 1 if ($dollarSign == 2);
                  push @quarks, "" if ($bracketed == 1);
                  shift @chars;
                }
                #shift @quarks if ($quarks[0] eq "");
                pop @quarks if ($quarks[-1] eq "");
#say "-quarks: ", join ",", @quarks;
                
                foreach my $q (0 .. $#quarks) {
                  if ($quarks[$q] =~ /<(.*?)>/) {
                    $quarks[$q] = catContents ($1);
                  } elsif ($quarks[$q] =~ /^\$0*(\d+)$/) {
                    if ($1 > $#tentAbsAvant + 1) {
                      warn "Backreference value greater than \$", $#tentAbsAvant + 1, " found in rule ", $scNum + 1, "\n";
                      next RULE;
                    } elsif ($1 == 0) {
                      warn "Meaningless backreference \$0 found in rule ", $scNum + 1, " (indexes start at 1)\n";
                      next RULE;
                    } else {
                      $quarks[$q] = "\$theAvant[$1]";
                    }
                  }
                }
                
                while ($#quarks > 0) {
                  my @one = split /\|/, shift @quarks;
                  my @two = split /\|/, shift @quarks;
                  my @tmp = ();
                  foreach my $one (@one) {
                    foreach my $two (@two) {
                      push @tmp, "$one$two";
                    }
                  }
                  unshift @quarks, join "|", @tmp;
                  $quarks[0] = "" unless (defined $quarks[0]);
#say "-quark: ", $quarks[0];
                }
                
                push @newSubunits, $quarks[0];
#say "-newSubunits: ", join ",", @newSubunits;
              }
              push @newUnits, join "|", @newSubunits;
#say "-newUnits: ", join ",", @newUnits;
            }
            
            $positive .= "|";
            my @negative = split "\\|", join "|", @newUnits;
#say "negative: ", join ",", @negative;
            foreach my $negative (@negative) {
              $negative =~ s/\\/\\\\/g;
              $negative =~ s/\\\\\\/\\/g;
              $negative =~ s/\$/\\\$/g;
              $negative =~ s/\[/\\\[/g;
              $negative =~ s/\]/\\\]/g;
              $positive =~ s/\|$negative\|/\|/g;
            }
            $positive =~ s/^\|//;
            $positive =~ s/\|$//;
            
            my $oldPositive;
            my $min;
            my $max;
            if ($suffix == -1) {
              $oldPositive = $positive;
              $min = 1;
              $max = 1;
            } else {
              $oldPositive = $tentAbsAvant[$suffix - 1];
              $oldPositive =~ s/^\(//;
              $oldPositive =~ s/\)\{(\d*),(\d*)\}\??$//;
              $min = $1;
              $max = $2;
              if ($oldPositive =~ /^\(\?!(.*?)\)\.$/) {
                $oldPositive = $1;
              }
            }
            $oldPositive =~ s/\\(\d+)/\$theAvant[$1]/g;
            
            if ($oldPositive =~ /^\(\?!/) {
              warn "Backreference to a complement found in rule ", $scNum + 1, "\n";
              next RULE;
            }
            
            if ($positive eq "") {
              if ($suffix == -1) {
                warn "Useless empty string in the second half of rule ", $scNum + 1, "\n";
                next RULE;
              } else {
                $positive = $oldPositive;
              }
            } elsif (($positive =~ tr/\|//) > 0) {
              if ($suffix == -1) {
                warn "Backreference needed for <$positive> in rule ", $scNum + 1, "\n";
                next RULE;
              }
            }
            if (($positive =~ tr/\|//) < ($oldPositive =~ tr/\|//)) {
              warn "Length mismatch for \$$suffix found in rule ", $scNum + 1, " (", ($positive =~ tr/\|//) + 1, " < ", ($oldPositive =~ tr/\|//) + 1, ")\n";
              next RULE;
            }
            if ($exact && ($positive =~ tr/\|//) != ($oldPositive =~ tr/\|//)) {
              warn "Length mismatch for \$$suffix found in rule ", $scNum + 1, " (", ($positive =~ tr/\|//) + 1, " != ", ($oldPositive =~ tr/\|//) + 1, ")\n";
              next RULE if ($exact == 2);
            }
            push @tentAbsApres, [$oldPositive, $min, $max, $positive, $suffix];
          }
        next RULE if ($#tentAbsAvant == -1);
        }
        push @absAvant, [@tentAbsAvant];
        push @absApres, [@tentAbsApres];
        $persist .= $tentPersist;
        $repeat .= $tentRepeat;
        push @dialects, $tentDialects;
        push @dialectsPersist, $tentDialects unless ($tentPersist eq "");
      } # if (defined $rule[0])
      $scNum++;
    } elsif (/=/) {
      (my $cat, my $contents) = split /=/, $_, 2;
      $cat = trim ($cat);
      $contents = trim ($contents);
      parseCat ($cat, $contents);
    } elsif (/^(IMPORT|INCLUDE)\s+(.+)$/i) {
      eval "rules (escapeString (\"$2\"), $lvl) or die";
      die "$@" if (defined $@ && $@ ne ""); # "$rules not found"
    } elsif (/^DIAL(ECTS)?\s+(\S*)$/i) {
      $dialect .= $2;
    } elsif (/^COND(ITIONS)?\s+(.*)/i) {
      parseCond (uc $2);
    } elsif (/^NAME\s+(.?)\s+(.+)$/i) {
      $name{codepoint ($1)} = $2;
    } elsif (/^#(:*)(\s*)(.*)$/) {
      push @colon, $scNum, length $1, $3;
    } else {
      warn "Unparsable statement \"$_\" ignored\n" unless ($skipping);
    }
  }
  close $rulesRef;
}

#say "col: ", join ",", @colon;
#say "aav:";
#foreach (0 .. $#absAvant) {
#  foreach (@{$absAvant[$_]}) {
#    say "$_";
#  }
#  say "EOL";
#}
#say "aap:";
#foreach (0 .. $#absApres) {
#  my @tap = @{$absApres[$_]});
#  foreach (0 .. $#tap) {
#    my @qwe = @{$tap[$_]};
#    foreach (@qwe) {
#      say "$_";
#    }
#    say "EOU";
#  }
#  say "EOL";
#}
#foreach my $name (keys %cats) {
#  print "$name: ";
#  foreach (0 .. $#{$cats{$name}}) {
#    print "@{$cats{$name}}[$_],";
#  }
#  say "";
#}
#say "p:   [$persist]";
#say "r:   [$repeat]";
#say "d: [$dialect]";
#say "d:   ", join ",", @dialects;
#say "dp:  ", join ",", @dialectsPersist;
#say "w:   ", join ",", @words;
#say "rul: ", $#absAvant + 1;

######## WORDS ########

my @theAvant;
my @theApres;

$dialect = " " if ($dialect eq "");
foreach my $dial (split //, $dialect) {
  next unless ($reqDial eq "" || $reqDial =~ $dial);
  record ("$dial:\n") if (length $dialect > 1);
  my @colonCopy = @colon;
  foreach my $word (@words) {
    chomp if (defined $_); # The condition is to suppress an annoying EOF error.
    #$word = encode ("utf8", $word);
    $limit = $maxLimit;
    $edit = 1 if ($edit == -1);
    my $original = my $wordCopy = $word;
    record ($wordCopy) unless ($mode == 0);
    my @index;
    SC: for (my $sc = 0; $sc <= $#absAvant; $sc++) {
      while ($#colonCopy + 1 && $colonCopy[0] == $sc) {
        shift @colonCopy;
        if ($colonCopy[0] <= $colonThreshold) {
          record ("\n" . $colonCopy[1]) if ($mode >= 2);
          record ("\n") unless (defined $colonCopy[3] && $colonCopy[2] == $sc && $colonCopy[3] <= $colonThreshold);
        }
        shift @colonCopy;
        shift @colonCopy;
      }
      
      my $old = $wordCopy;
      next SC if ($persist =~ /,$sc,/);
      next SC unless ($dialect eq " " || $dialects[$sc] eq "" || $dialects[$sc] =~ escape ($dial));
      
      @index = regindex ($wordCopy, $sc);
      my $offset = 0;
      while (@index > 0) {
        ($wordCopy, $offset) = replace ($sc, $wordCopy, $offset, shift @index, shift @index);
      }
      $wordCopy = edit (" > ", $wordCopy) if ($mode >= 3 && ($notAll == 0 || $wordCopy ne $old));
      $limit--;
      die "\n\n\nError: Infinite repetition\n\n\n" if ($limit == 0);
      
      record (" [") if (length $persist > 1 && $mode >= 3);
      PSC: for (my $psc = 0; $psc <= $#absAvant; $psc++) {
        my $oldP = $wordCopy;
        next PSC unless ($persist =~ /,$psc,/);
        next PSC unless ($dialect eq " " || $dialectsPersist[$psc] eq "" || $dialectsPersist[$psc] =~ escape ($dial));
        @index = regindex ($wordCopy, $psc);
        my $offset = 0;
        while (@index > 0) {
          ($wordCopy, $offset) = replace ($psc, $wordCopy, $offset, shift @index, shift @index);
        }
        $wordCopy = edit (" > ", $wordCopy) if ($mode >= 3 && ($notAll == 0 || $wordCopy ne $old));
        $limit--;
        die "\n\n\nError: Infinite repetition\n\n\n" if ($limit == 0);
        $psc-- if ($repeat =~ /,$psc,/ && $wordCopy ne $oldP);
      } # PSC
      record ("]") if (length $persist > 1 && $mode >= 3);
      
      $wordCopy = edit (" > ", $wordCopy) if ($mode == 2 && ($notAll == 0 || $wordCopy ne $old));
      $sc-- if ($repeat =~ /,$sc,/ && $wordCopy ne $old);
    } # SC
    $wordCopy = edit (" > ", $wordCopy) if ($mode == 1 && ($notAll == 0 || $wordCopy ne $original));
    record ($wordCopy) if ($mode == 0);
    record ("\n");
  }
}

######## SOUND-CHANGING SUBROUTINES ########

sub regindex {
  my $word = shift;
  my $scNum = shift;
  my $regex;
  my @avant = @{$absAvant[$scNum]};
  foreach (0 .. $#avant) {
    $regex .= "($avant[$_])";
  }
  
  my @ret;
  my @ref = ();
  my $greatestIndex = 0;
  for (my $i = 0; $i < length $word; $i++) {
    die "\nError: Long word\n" if ($i > 32766);
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
  @theAvant = @ref;
  return @ret;
}

sub replace {
  my $scNum = shift;
  my $word = shift;
  my $os = shift;
  my $pos = $os + shift;
  my $len = shift;
  my @apres = @{$absApres[$scNum]};
  my $pre = substr ($word, 0, $pos);
  my $post = substr ($word, $pos);
  my @avant = (0);
  my $theAvantShift = shift @theAvant;
  push @avant, shift @theAvant foreach (1 .. $theAvantShift);
  
  my $apres;	
  foreach (0 .. $#apres) {
    (my $old, my $min, my $max, my $new, my $suffix) = @{$apres[$_]}[0 .. 4];
    if ($suffix == -1) {
      $apres .= $new;
    } else {
      $old =~ s/\$theAvant\[(\d+)\]/$avant[$1]/g;
      $new =~ s/\$theAvant\[(\d+)\]/$avant[$1]/g;
      my $unit = $avant[$suffix];
      my $matched;
      my @units;
      my @blacklist = ();
      for (my $i = 0; ($max eq "" || $max > $i) && length $unit >= 1; $i++) {
        my $lookFor = blacken ($old, $blacklist[$i]);
        $unit =~ s/($lookFor)$//;
        $matched = $1;
        unshift @units, $matched;
      }
      if ($#units + 1 < $min || $max ne "" && $#units > $max) {
        defined $units[-1] ? $blacklist[0] .= "|$units[-1]" : $blacklist[0] .= "";
        for (my $i = 0; $blacklist[$i] eq "|$old"; $i++) {
          push @blacklist, "" x $i - $#blacklist + 1 if ($i > $#blacklist);
          $blacklist[$i] = "";
          $blacklist[$i + 1] .= "|$units[-$i - 1]";
        }
        @units = ();
      }
      
      my $index = -1;
      foreach my $unit (@units) {
        my @old = split /\|/, $old;
        foreach (0 .. $#old) {
          if ($unit eq $old[$_]) {
            $index = $_;
            last;
          }
        }
        $apres .= ((split /\|/, $new), "")[$index]; # $index will never be -1
      }
    }
  }
  
  die "\nError: Long word\n" if ($len > 32766);
  
  defined $apres ? eval "\$post =~ s/.\{$len\}/$apres/" : eval "\$post =~ s/.\{$len\}//";
  $os += length ("$pre$post") - length ($word);
  return ("$pre$post", $os);
}

sub blacken {
  my $white = "|" . shift;
  my $black = shift;
  $black = "" unless (defined $black);
  $white =~ s/$black//g;
  $white =~ s/^\|//;
  return $white;
}

######## CATEGORY SUBROUTINES ########

sub parseCat {
  my $cat = shift;
  warn "Overwriting <$cat>\n" if (exists $cats{$cat});
  if($cat =~ /(\s|\+|-|<|>|\|)/) {
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

sub catContents {
  my $name = shift;
  my @fish;
  unless (exists $cats{$name}) {
    warn "Uninitialized category: <$name>\n";
    return "";
  }
  foreach (0 .. $#{$cats{$name}}) {
    push @fish, @{$cats{$name}}[$_];
  }
  return join ("|", @fish);
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
  print $output $str if (defined $output);
  my @chars = split //, $str;
  $str = "";
  foreach (@chars) {
    if ($nfkd) {
      $str .= substr NFKD $_, 0, 1;
    } elsif (defined $name{codepoint ($_)}) {
      $str .= $name{codepoint ($_)};
    } else {
      $str .= $_;
    }
  }
  $html || $unicode ? print STDOUT html ($str) : print $str;
}

sub html {
  my @chars = split //, $_[0];
  my $ret = "";
  foreach (@chars) {
    if ($html && defined $html{codepoint ($_)}) {
      $ret .= $html{codepoint ($_)};
    } elsif ($unicode && $wysiwyg !~ escape ($_)) {
      my $charname = charnames::viacode("0x" . codepoint ($_));
      if (defined $charname) {
        $ret .= "{" . charnames::viacode("0x" . codepoint ($_)) . "}";
      } else {
        $ret .= "{U+" . codepoint ($_) . "}";
      }
    } else {
      $ret .= $_;
    }
  }
  return $ret;
}

sub codepoint {
  my $char = $_[0];
  return sprintf ("%.4X", unpack ("U0U*", $char));
}

sub escape {
  my $ret;
  foreach (split //, shift) {
    eval "'' =~ /$_/";
    $ret .= "\\" if (defined $@ && $@ ne "");
    $ret .= $_;
  }
  return $ret;
}

sub escapeString {
  my $ret;
  foreach (split //, shift) {
    eval "'$_'";
    $ret .= "\\" if (defined $@ && $@ ne "");
    $ret .= $_;
  }
  return $ret;
}