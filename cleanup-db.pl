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
my ( $files_rejected, $files_passed ) = ( 0, 0);

my $basepath = "";
Getopt::Long::GetOptions ('basepath=s' => \$basepath, "help|h|?" => sub { print <<EOT;
usage:
 --basepath PATH : select which directory from the db to use (as there might be multiple runs with "scan-files DIR", the same DIR has to appear here. default is to scan for all files that are equipped with a hash.
EOT
exit 0; }
) ;

sub dropFile{
	my $id = shift or 0;
	die "no ID given" if ( $id == 0 );
	my $rows = $dbh->do('delete from filecollector where id = ?', undef, $id) or die "Could not remove from DB: $DBI::errstr";
	print "\n  file with ID $id removed from DB, $rows deleted\n";
}

# begin sub main

$dbh = DBI->connect('DBI:mysql:filecollector;host=hive.ak-online.be', 'filecollector', Digest::MD5::md5_hex("this password protects nothing for real") ) || die "Could not connect to database: $DBI::errstr";
$dbh->do(qq{SET NAMES 'utf8';});
$dbh->{'mysql_enable_utf8'} = 1;

print "connected\n";

my $selector = "SELECT * from filecollector";

if ( $basepath ne "" ) {
	$selector = "SELECT * from filecollector where basedir = $basepath";
}


my $resultset = $dbh->selectall_hashref( $selector , "id");
FILE: foreach my $id ( keys %$resultset ) {
	my $basedir	= $resultset->{$id}->{"basedir"};
	my $path	= $resultset->{$id}->{"path"};
	my $filename	= $resultset->{$id}->{"filename"};

	my ( $fullfilename, $hash);
	if ( $path eq "" ) {
		$fullfilename = "$basedir/$filename";
	} else {
		$fullfilename = "$basedir/$path/$filename";
	}

	print "checking file: $fullfilename\t";

	# if file is a symlink remove it - no need to hash the target
	if ( -l "$fullfilename" ) {
		print "SYMLINK\t";
		eval {
			dropFile($id);
		} and $files_rejected++;
		next FILE
	} else {
		print "!symlink\t";
	}

	# if file does not exist remove it
	if ( ! -f "$fullfilename" ) {
		print "does not exist";
		eval {
			dropFile($id);
		} and $files_rejected++;
		next FILE
	} else {
		print "exists";
	}
	print "\n";

	# if any of the path-components is a symlink
	# remove the file from the db
	my $full_path = $basedir;
	foreach my $path_component ( split (/\// , $path) ) {
		$full_path .= "/$path_component";
		print "  traversing path: $full_path\t";
		if ( -l $full_path ) {
			print "SYMLINK\t";
			eval {
				dropFile($id);
			} and $files_rejected++;
			next FILE
		} else {
			print "!symlink\t";
		}
		print "\n";
	}

	# if we've come so far, the file in question has passed
	$files_passed++;
}

print "\n\nReport:\n  files passed checks: $files_passed\n  files failed checks: $files_rejected\n";

$dbh->disconnect();
