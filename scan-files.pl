#!/usr/bin/perl

use warnings;
use strict;

use Digest::MD5;

use DBI;

our $dbh;

sub push_db  {
	my $basedir	= shift;
	my $path	= shift;
	my $filename	= shift;

	print "found file: $basedir\t/\t$path\t/\t$filename\n";
	$dbh->do('INSERT INTO filecollector (basedir, path, filename) VALUES(?, ?, ?)', undef, ( $basedir, $path, $filename));

}
sub ScanDirectory{
	my $basedir	= shift;
	my $path	= shift;

	opendir(DIR, "$basedir/$path") or die "unable to open $basedir/$path:\n$!" ;
	my @names = readdir(DIR) or die "unable to read $basedir/$path:\n$!\n";
	closedir(DIR);

	foreach my $name (@names){
		next if ($name eq "."); 
		next if ($name eq "..");

		if ( -f "$basedir/$path/$name" ){
			push_db( "$basedir", "$path","$name" );
			next;
		}

		my $dirname = "";
		if ( $path eq "" ) {
			$dirname = "$name";
		} else {
			$dirname = "$path/$name";
		}

		if ( -d "$basedir/$dirname"){
			eval { ScanDirectory("$basedir", "$dirname"); };
			if ( $@ ) {
				print "Skipping directory $basedir/$dirname as I am $@\n";
			}
			next;
		}
	}
}

# begin sub main

$dbh = DBI->connect('DBI:mysql:filecollector;host=hive.ak-online.be', 'filecollector', Digest::MD5::md5_hex("this password protects nothing for real") ) || die "Could not connect to database: $DBI::errstr";
$dbh->do(qq{SET NAMES 'utf8';});
$dbh->{'mysql_enable_utf8'} = 1;

foreach ( @ARGV ) {
	print "starting with $_\n";
	eval { ScanDirectory($_, ""); };
	if ( $@ ) {
		print "Skipping argument $_ as I am $@\n";
		next;
	}
}

$dbh->disconnect();
