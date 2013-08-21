#!/usr/bin/perl

# $Id: tunssh.pl 184 2010-03-11 10:29:01Z martijn $

# Create an persistant SSH tunnel and set a lock file.
# Useful for doing remote Rsync backups over SSH.
#
#
# 03/2010 Martijn Pepping <martijn@xbsd.nl>



use strict; 
use warnings;


# You might want to set these
my $username='username';
my $hostname="host.example.com";
my $localport=10873;
my $remoteport=873;
my $lckfile="/tmp/tunssh.${hostname}.pid";



# subs
#

sub start_ssh {

    # fork!
    defined( my $pid=fork ) or die "cannot fork process: $!";

    # parent - open lockfile with child pid
    if($pid) {

        print "Starting process: $pid\n";

        open(LOCKFILE,">$lckfile") or die "Cannot create lock file: $!";
        print LOCKFILE "${pid}";
        close(LOCKFILE);

    } else {

        # child - start ssh
        exec("ssh -nNT -L ${localport}:127.0.0.1:${remoteport} ".
             "${username}\@${hostname}")
          or die "cannot exec process\n";
    }

}



# main
#

if(! -e $lckfile) {

    start_ssh();

} else {

    # get running(?) pid from pid file
    @ARGV = ($lckfile);my $old_pid = <ARGV>;
    my $running = kill 0, $old_pid;


    # lock file exists - is process still running?
    if ( $running == 1 ) {
        die "Process running: $old_pid\n";
    } else {
        # check lockfile was deleted!
        if(! unlink $lckfile) {
              die "Lockfile not deleted\n";
          }
        print "Orphan lock file - Lock file deleted\n\t";

        start_ssh();
    }
}
