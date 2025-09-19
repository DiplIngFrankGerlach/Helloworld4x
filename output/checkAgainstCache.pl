#!/usr/bin/perl

################################################################################
# Sappeur support script that enables the make program to C++ compile only 
# c++ files, which have actually changed.
# A copy of the previous Sappeur compilation run is maintained in the cache
# directory.
#################################################################################





use strict;
use warnings;
use Time::Local;
use File::Copy;


# Open a pipe to the external program
open(my $fh, "md5sum *.cpp *.h|") 
    or die "Failed to execute md5sum";

my %fingerprints;

# Loop over the stdout of the external program
while (my $line = <$fh>) {
    chomp $line;  # Remove the newline character

    if ( $line =~ /^(\S+) [*](\S+)/ ) 
    {
       #printf("$1 $2\n");

       my $file = $2;
       my $hash = $1;
       $fingerprints{$file} = $hash;
    }
}

# Close the file handle
close($fh) 
    or warn "Error closing pipe: $!";


# Open a pipe to the external program
open(my $fhc, "md5sum cache/*.cpp cache/*.h|") 
    or die "Failed to execute md5sum";

my %fingerprintsCache;

# Loop over the stdout of the external program
while (my $line = <$fhc>) {
    chomp $line;  # Remove the newline character

    if ( $line =~ /^(\S+) [*]cache\/(\S+)/ ) 
    {
       #printf("Cache $1 $2\n");
       my $file = $2;
       my $hash = $1;
       $fingerprintsCache{$file} = $hash;
    }
}

# Close the file handle
close($fhc) 
    or warn "Error closing pipe: $!";

foreach my $file (keys %fingerprints) {
    #print "$key => $hash{$key}\n";
    my $hc =  $fingerprints{$file}; 

    my $hcCache = $fingerprintsCache{ $file };
    if( exists $fingerprintsCache{ $file } && ($hc eq $hcCache) )
    {  
        # Get the current time
        my @current_time = localtime();

        # Calculate midnight for today
        # Reset hour, minute, and second to 0
        my $midnight = timelocal(0, 0, 0, $current_time[3], $current_time[4], $current_time[5]);

        # Set the file's access and modification times to midnight
        utime($midnight, $midnight, $file)
    }
    else
    {
       printf("File $file changed\n"); 
       copy($file, "cache")
    }
    
}
