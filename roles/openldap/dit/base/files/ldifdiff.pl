#!/usr/bin/perl -w
# GPL copyright 2004 by VA Linux Systems Japan, K.K
#   Writen by Masato Taruishi <taru@valinux.co.jp>
#
# Copyright (c) 2011 SATOH Fumiyasu @ OSS Technology, Inc.
#               <http://www.osstech.co.jp/>
#

=head1 NAME

ldif-diff - compare two ldif files

=head1 SYNOPSIS

B<ldif-diff> [<options..>] <old> <new>

=head1 DESCRIPTION

B<ldif-diff> compares two ldif(5) files and prints the difference
in the format of the reduced slapd.replog(5) for ldapmodify(1).

If you modify the directory which consists of entries specified
by the old ldif file by using the output, then the directory will
be same as the directory which consists of entries specified by
the new ldif file. So, you can use this program to synchronize
two LDAP servers.

=head1 OPTIONS

=head2 --dn=<regex> | d=<regex>

Specify the regular expression which matches DNs to be handled.
You can specify this option many times.

=head2 --include-attrs=<attrs> | i=<attrs>

Specify the comma-separated list of attributes to be checked. The specified
attributes here are checked even if you specify it in B<--exclude-attrs>.

=head2 --exclude-attrs=<attrs> | e=<attrs>

Specify the comma-separated list of additional attributes to be
excluded from checking.
By default, the following attributes are excluded. If you want to check
these attributes, then specify the attributes in B<--include-attrs>.

  modifyTimestamp
  modifiersName
  entryCSN
  entryUUID
  createTimestamp
  creatorsName
  structuralObjectClass

=head1 SEE ALSO

slapd.replog(5), ldapmodify(1), ldif(5)

=head1 AUTHOR

Masato Taruishi <taru@valinux.co.jp>

=cut

use strict;
use MIME::Base64;
use Getopt::Long;
use File::Temp qw/ tempfile /;

my %exclude_attr = (
  "modifyTimestamp" => 1,
  "modifiersName" => 1,
  "entryCSN" => 1,
  "entryUUID" => 1,
  "createTimestamp" => 1,
  "creatorsName" => 1,
  "structuralObjectClass" => 1,
);

my %include_attr = ();

my @dn_regex;

sub usage {
	print STDERR <<EOF;
Usage: ldif-diff [<options..>] <old> <new>
EOF
}

sub debug {
 print STDERR join('\n', @_ ) if $ENV{DEBUG};
}

my $exattrs = "";
my $incattrs = "";
my $dn_regex = ".*";

GetOptions('exclude-attrs|e=s' => \$exattrs,
           'include-attrs|i=s' => \$incattrs,
	   'dn|d=s' => \@dn_regex
);

foreach ( split(/,/, $exattrs) ) {
  $exclude_attr{$_} = 1;
}

foreach ( split(/,/, $incattrs) ) {
  $include_attr{$_} = 1;
}

$dn_regex = join( "|", @dn_regex ) if @dn_regex;

# sub <in>
sub entry {
  my $in = shift;
  my $buf = "";
  my $e = "";
  while ( <$in> ) {
    next if ( !( $_ =~ /^#/ ));

    if ( $_ eq "\n" ) {
      goto BREAK if !($_ eq "");
      next;
    }

    if( $_ =~ /^([^:]+):/ ) {
      if( $include_attr{$1} ) {
	$buf = $buf . $_;
      } elsif( ! $exclude_attr{$1} ) {
	$buf = $buf . $_;
      }
    } else {
      if ( $_ =~ /^\s+(.*)/ ) {
	chomp $buf;
	$buf = $buf . $1 . "\n";
      }
    }
  }
BREAK:
   return $buf;
}

sub decode {
  my $buf = shift;
  my $dec = "";
  foreach (split(/\n/, $buf) ) {
    if( $_ =~ /(\S+)::\s*(.*)/ ) {
      $dec = $dec . $1 . ": " . decode_base64( $2 );
    } elsif( $_ =~ /(\S+):</ ) {
      die ":< attribute not supported yet";
    } else {
      $dec = $dec . $_;
    }
    $dec = $dec . "\n";
  }
  return join("\n", sort ( split /\n/, $dec ));
}

sub modify {

  ( my $oldentry, my $newentry, my $oldentry_decode, my $newentry_decode, my $dn, my $modfh ) = @_;

  debug "different: $dn\n";
  debug "[$oldentry_decode]\n";
  debug "[$newentry_decode]\n";

  my %oldattr = ();
  my %oldattr_decode = ();
  my %newattr = ();
  my %newattr_decode = ();

  print $modfh "dn: $dn\n";

  print $modfh "changetype: modify\n";

  foreach (split /\n/, $oldentry) {
    debug "adding old attr: $_ for $dn\n";
    if ( $_ =~ /(([^:]+)(:+)\s*.+)/ ) {
      $oldattr{$2} = "" if ! $oldattr{$2};
      $oldattr{$2} = $oldattr{$2} . $1 . "\n";
    } else {
      print STDERR "Unsupported ldif format: $_\n";
    }
  }

  foreach (split /\n/, $oldentry_decode) {
    if ( $_ =~ /(([^:]+)(:+)\s*.+)/ ) {
      $oldattr_decode{$2} = "" if ! $oldattr_decode{$2};
      $oldattr_decode{$2} = $oldattr_decode{$2} . $1;
    } else {
      print STDERR "Unsupported ldif format: $_\n";
    }
  }

  foreach (split /\n/, $newentry) {
    debug "adding new attr: $_ for $dn\n";
    if ( $_ =~ /(([^:]+)(:+)\s*.+)/ ) {
      $newattr{$2} = "" if ! $newattr{$2};
      $newattr{$2} = $newattr{$2} . $1 . "\n";
    } else {
      print STDERR "Unsupported ldif format: $_\n";
    }
  }

  foreach (split /\n/, $newentry_decode) {
    if ( $_ =~ /(([^:]+)(:+)\s*.+)/ ) {
      $newattr_decode{$2} = "" if ! $newattr_decode{$2};
      $newattr_decode{$2} = $newattr_decode{$2} . $1;
    } else {
      print STDERR "Unsupported ldif format: $_\n";
    }
  }

  foreach (keys %oldattr) {
    debug "checking attr: $_ for $dn\n";
    if( ! $newattr{$_} ) {
      debug "attr delete: $_\n";
      print $modfh "delete: $_\n";
      print $modfh "-\n";
    } else {
      if( !($oldattr_decode{$_} eq $newattr_decode{$_}) ) {
        debug "attr modify: $_ -> $newattr{$_}\n";
        print $modfh "replace: $_\n";
        foreach my $v (split /\n/, $newattr{$_}) {
          print $modfh "$v\n";
        }
        print $modfh "-\n";
      }
    }
    delete $oldattr{$_};
    delete $newattr{$_};
  }
	
  foreach (keys %newattr) {
    debug "attr add: $_\n";
    print $modfh "add: $_\n";
    foreach my $v (split /\n/, $newattr{$_}) {
      print $modfh "$v\n";
    }
    print $modfh "-\n";
    delete $newattr{$_};
  }

  print $modfh "\n";
}

if ( $#ARGV != 1 ) {
  usage;
  exit 1;
}

my $oldfile = $ARGV[0];
my $newfile = $ARGV[1];

my %oldentry = ();
my %oldentry_decode = ();
my %newentry = ();
my %newentry_decode = ();

(my $modfh, my $modfile) = tempfile();

open( my $oldin, $oldfile ) or die "Couldn't read $oldfile: $!";
open( my $newin, $newfile ) or die "Couldn't read $oldfile: $!";

while(  (!eof( $oldin )) ||  (!eof( $newin )) ) {

  # Current DN
  my $odn = "";
  my $ndn = "";
  my $e;

  # Fetch the next entry from the old
  $e = entry( $oldin );
  if ( $e =~ m/dn: ($dn_regex)/o ) {
    $odn = $1;
    debug "O: read: $odn\n";
    $oldentry{$odn} = $e;
  }

  # Fetch the next entry from the new
  $e = entry( $newin );
  if ( $e =~ m/dn: ($dn_regex)/o ) {
    $ndn = $1;
    debug "N: read: $ndn\n";
    $newentry{$ndn} = $e;
  }

  # Check wether the current entry exists both
  if ( $newentry{$odn} && $oldentry{$odn} ) {
    debug "checking $odn\n";
    $oldentry_decode{$odn} = decode($oldentry{$odn}) if ! $oldentry_decode{$odn};

    $newentry_decode{$odn} = decode($newentry{$odn}) if ! $newentry_decode{$odn} ;
    if ( $newentry_decode{$odn} ne $oldentry_decode{$odn} ) {
      modify($oldentry{$odn}, $newentry{$odn}, $oldentry_decode{$odn},
             $newentry_decode{$odn}, $odn, $modfh);
    } else {
      debug "same: $odn\n";
    }
    delete $oldentry{$odn};
    delete $oldentry_decode{$odn};
    delete $newentry{$odn};
    delete $newentry_decode{$odn};
  }

  if ( $newentry{$ndn} && $oldentry{$ndn} ) {
    $oldentry_decode{$ndn} = decode($oldentry{$ndn}) if ! $oldentry_decode{$ndn} ;
    $newentry_decode{$ndn} = decode($newentry{$ndn}) if ! $newentry_decode{$ndn} ;
    if ( $newentry_decode{$ndn} ne $oldentry_decode{$ndn} ) {
      modify($oldentry{$ndn}, $newentry{$ndn}, $oldentry_decode{$ndn}, $newentry_decode{$ndn}, $ndn, $modfh);
    } else {
      debug "same: $ndn\n";
    }
    delete $oldentry{$ndn};
    delete $oldentry_decode{$ndn};
    delete $newentry{$ndn};
    delete $newentry_decode{$ndn};
  }
}

close $modfh;
close $oldin;
close $newin;

foreach ( sort { length($b) <=> length($a); } keys %oldentry ) {
  debug "delete: $_\n";
  print "dn: $_\n";
  print "changetype: delete\n";
  print "\n";
}

foreach ( sort { length($a) <=> length($b);  } keys %newentry ) {
  debug "add: $_\n";
  print "dn: $_\n";
  print "changetype: add\n";
  foreach my $v (split /\n/, $newentry{$_}) {
    print "$v\n" if ! ( $v =~ /^dn:/ );
  }
  print "\n";
}

open( MOD, $modfile ) || die "$!";
while(<MOD>) {
  print "$_";
}

