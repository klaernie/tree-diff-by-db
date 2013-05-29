#!/usr/bin/perl

use warnings;
use strict;

use Digest::MD5;

use DBI;


sub push_db  {
	my $basedir	= shift;
	my $path	= shift;
	my $filename	= shift;

#	print "$basedir\t/\t$path\t/\t$filename\n";

}
sub ScanDirectory{
	my $basedir	= shift;
	my $path	= shift;

	opendir(DIR, "$basedir/$path") or die "Unable to open $basedir/$path:$!\n";
	my @names = readdir(DIR) or die "Unable to read $basedir/$path:$!\n";
	closedir(DIR);

	foreach my $name (@names){
		next if ($name eq "."); 
		next if ($name eq "..");

		if ( -f "$basedir/$path/$name" ){
			push_db( "$basedir", "$path","$name" );
			next;
		}

		if ( -d "$basedir/$path/$name"){
			ScanDirectory("$basedir", "$path/$name");
			next;
		}
	}
}

# begin sub main

our $dbh = DBI->connect('DBI:mysql:filecollector;host=hive.ak-online.be', 'filecollector', Digest::MD5::md5_hex("this password protects nothing for real") ) || die "Could not connect to database: $DBI::errstr";

foreach ( @ARGV ) {
	ScanDirectory($_, "");
}

$dbh->disconnect();
