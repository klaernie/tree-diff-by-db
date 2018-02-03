#!/usr/bin/perl

use warnings;
use strict;

use utf8;
use open ':std', ':encoding(UTF-8)';

use DBI;

our $dbh;

sub push_db  {
	my $basedir	= shift;
	my $path	= shift;
	my $filename	= shift;
	my @fileinfo	= stat("$basedir/$path/$filename");

	print "found file: $basedir\t/\t$path\t/\t$filename\n";

	$dbh->do('INSERT IGNORE INTO filecollector (basedir, path, filename, created, accessed, changed, size,  filenamehash)
		  VALUES(?, ?, ?, ?, ?, ?, ?, sha1( concat(basedir,"/",path,"/",filename)))', undef,
		 ( $basedir, $path, $filename, $fileinfo[8], $fileinfo[9], $fileinfo[10], $fileinfo[7]));
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

		# if the item in question is a symlink
		#  - pointing to a directory:
		#      the contents are to be checked either in
		#        - this basedir, but a different, non-symlink folder
		#        - another basedir
		#        - not at all
		# - pointing to a regular file
		#      the file is either
		#        - in another basedir
		#        - already in this basedir
		#        - possibly already hashed
		next if ( -l "$basedir/$path/$name" );

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

my $configfile="config.pl";
{
	package cfg;
	do "./$configfile" || die "could not read $configfile";
}
die "no DSN given in configfile"         unless ($cfg::DSN);
die "no DB user given in configfile"     unless ($cfg::db_user);
die "no DB password given in configfile" unless ($cfg::db_passwd);

$dbh = DBI->connect($cfg::DSN, $cfg::db_user, $cfg::db_passwd) || die "Could not connect to database: $DBI::errstr";

# if the DB type is mysql make sure UTF-8 works
if ($cfg::DSN=~ m/mysql/) {
	$dbh->do(qq{SET NAMES 'utf8';});
	$dbh->{'mysql_enable_utf8'} = 1;
}

if ( scalar @ARGV < 1 ) {
	print <<EOT;
usage:
  scan-files.pl DIR [ … DIR]

  DIR: can be use multiple times, each dir is check for files, and each found file is written to the db.
EOT

}
foreach ( @ARGV ) {
	print "starting with $_\n";
	eval { ScanDirectory($_, ""); };
	if ( $@ ) {
		print "Skipping argument $_ as I am $@\n";
		next;
	}
}

$dbh->disconnect();
