#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Digest::MD5 qw(md5_hex);
use Digest::SHA;

use DBI;

our $dbh;

# begin sub main

$dbh = DBI->connect('DBI:mysql:filecollector;host=hive.ak-online.be', 'filecollector', Digest::MD5::md5_hex("this password protects nothing for real") ) || die "Could not connect to database: $DBI::errstr";
$dbh->do(qq{SET NAMES 'utf8';});
$dbh->{'mysql_enable_utf8'} = 1;

print "connected\n";

chomp (my $basedir = shift);

my $resultset = $dbh->selectall_hashref("SELECT * from filecollector where basedir = '$basedir'", "id");
foreach my $id ( keys %$resultset ) {
	my $basedir	= $resultset->{$id}->{"basedir"};
	my $path	= $resultset->{$id}->{"path"};
	my $filename	= $resultset->{$id}->{"filename"};
	my $size	= $resultset->{$id}->{"size"};
	my $hash	= $resultset->{$id}->{"hash"};

	my $fullfilename = $basedir;
	$fullfilename .= "/$path" if ( $path ne "" );
	$fullfilename .= "/$filename";


	if ( ! -e $fullfilename ) {
		print "deleting id:$id: … ";
		eval { $dbh->do("delete from `filecollector`.`filecollector` WHERE id=?;", undef, $id ); };
		if ( $@ ) {
			print "could not delete row id:$id: $@\n";
			next;
		} else {
			print "done.\n";
		}
	} else {
		my $newsize = -s $fullfilename;
		next if $newsize == $size;

		if( $size > 0 ){
			$hash = undef;
		}
		print "updating id:$id: … ";
		eval { $dbh->do("update `filecollector`.`filecollector` set size = ?, hash = ? WHERE id=?;", undef, $newsize, $hash, $id ); };
		if ( $@ ) {
			print "could not update row id:$id: $@\n";
			next;
		} else {
			print "done.\n";
		}
	}
}

$dbh->disconnect();
