#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Getopt::Long;

use Digest::MD5 qw(md5_hex);
use Digest::SHA;

use DBI;

our $dbh;
my ( $hash_matched, $hash_unmatched ) = ( 0, 0);

my $logfile = "defective files";
my $orig_basepath = "";
my $new_basepath = "";
Getopt::Long::GetOptions ('logfile|log=s' => \$logfile, 'original-basepath=s' => \$orig_basepath, 'new-basepath=s' => \$new_basepath, "help|h|?" => sub { print <<EOT;
usage:
 --logfile FILE : specify an alternative location to write the logfile to instead of ./defective files
 --original-basepath PATH : select which directory from the db to use (as there might be multiple runs with "scan-files DIR", the same DIR has to appear here. default is to scan for all files that are equipped with a hash.
 --new-basepath PATH : replace the basepath that is stored in the db with this path, to check e.g. in another mountpoint
EOT
exit 0; }
) ;

sub HashFile {
	 my $filename = shift;
	 my $sha;
	 $sha = Digest::SHA->new(512) or die "I could not create hash-object:$@";
	 $sha->addfile($filename) or die "I could not read the file:$@";
	 return $sha->hexdigest or die "I could not retrieve the digest";
}

# begin sub main

$dbh = DBI->connect('DBI:mysql:filecollector;host=hive.ak-online.be', 'filecollector', Digest::MD5::md5_hex("this password protects nothing for real") ) || die "Could not connect to database: $DBI::errstr";
$dbh->do(qq{SET NAMES 'utf8';});
$dbh->{'mysql_enable_utf8'} = 1;

print "connected\n";

open ( LOG, ">$logfile" );

my $selector = "SELECT * from filecollector where hash IS NOT NULL";

if ( $orig_basepath ne "" ) {
	$selector = "SELECT * from filecollector where basedir = $orig_basepath and hash IS NOT NULL";
}
if ( $new_basepath ne "" ) {
	$selector = "SELECT id, \"$new_basepath\" as basedir, path, filename, hash from filecollector where hash IS NOT NULL";
}
if ( $orig_basepath ne "" and $new_basepath ne "" ) {
	$selector = "SELECT id, \"$new_basepath\" as basedir, path, filename, hash from filecollector where basedir = \"$orig_basepath\" and hash IS NOT NULL";
}


my $resultset = $dbh->selectall_hashref( $selector , "id");
foreach my $id ( keys %$resultset ) {
	my $basedir	= $resultset->{$id}->{"basedir"};
	my $path	= $resultset->{$id}->{"path"};
	my $filename	= $resultset->{$id}->{"filename"};

	my ( $fullfilename, $hash);
	if ( $path eq "" ) {
		$fullfilename = "$basedir/$filename";
	} else {
		$fullfilename = "$basedir/$path/$filename";
	}

	print "hashing id:$id | $fullfilename\n";
	eval { $hash = HashFile ( $fullfilename ); };
	if ( $@ ) {
		print "$fullfilename could not be hashed as $@\n";
		next;
	}

	if ( $hash ne $resultset->{$id}->{"hash"} ) {
		print "$fullfilename differs from stored hash\n";
		print LOG "$fullfilename\n";
		$hash_unmatched++;
	} else {
		$hash_matched++;
	}
}

print "\n\nReport:\n  correct hashes: $hash_matched\nuncorrect hashes: $hash_unmatched\n";

$dbh->disconnect();
close LOG;
