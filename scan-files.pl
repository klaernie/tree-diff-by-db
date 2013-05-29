#!/usr/bin/perl

use warnings;
use strict;

use Digest::MD5;

use DBI;


sub push_db  {
	my $pathname = shift;
	my $filename = shift;
	print "$pathname\t/\t$filename\n";
}
sub ScanDirectory{
	my ($searchdir) = shift; 

	opendir(DIR, "$searchdir") or die "Unable to open $searchdir:$!\n";
	my @names = readdir(DIR) or die "Unable to read $searchdir:$!\n";
	closedir(DIR);

	foreach my $name (@names){
		next if ($name eq "."); 
		next if ($name eq "..");

		if ( -f "$searchdir/$name" ){
			push_db( "$searchdir","$name" );
			next;
		}

		if ( -d "$searchdir/$name"){
			ScanDirectory("$searchdir/$name");
			next;
		}
	}
}

# begin sub main

#our $dbh = DBI->connect('DBI:mysql:filecollector;host=hive.ak-online.be', 'filecollector', Digest::MD5::md5_hex("this password protects nothing for real") ) || die "Could not connect to database: $DBI::errstr";

foreach ( @ARGV ) {
	ScanDirectory($_);
}

#$dbh->disconnect();
