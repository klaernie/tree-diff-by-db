#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open ':std', ':encoding(UTF-8)';

use Digest::MD5 qw(md5_hex);
use Digest::SHA;

use DBI;

our $dbh;

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
my $resultset = $dbh->selectall_hashref("SELECT * from filecollector where hash IS NULL", "id");
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

	if ( $hash ) {
		print "will update id:$id with hash $hash: … ";
		eval { $dbh->do("UPDATE `filecollector`.`filecollector` SET hash = ? WHERE id=?;", undef, $hash, $id ); };
		if ( $@ ) {
			print "could not update row id:$id: $@\n";
			next;
		} else {
			print "done.\n";
		}
		
	}
}

$dbh->disconnect();
