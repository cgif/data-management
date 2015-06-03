#!/usr/bin/perl

use strict;
use warnings;

my $sample_sheet=$ARGV[0];
my $run_info_xml=$ARGV[1];
my $lane=$ARGV[2];

#parse RunInfo.xml
my $flowcell_id=-1;
my $length_read1=-1;
my $length_idx_read1=-1;
my $length_idx_read2=-1;
my $length_read2=-1;

#parse run info
open(RI, "<$run_info_xml") or die "Unable to open RunInfo file $run_info_xml: $!\n";

while(<RI>){

	
	if(/<Flowcell>(.*?)<\/Flowcell>/){
	    
		$flowcell_id=$1;	
		#print "$flowcell_id\n";
		
	}
	
	
	my $match = 0;
	my $read_number=-1;
	my $cycles=-1;
	my $is_index=-1;

	#HiSeq RunInfo.xml
	if(/<Read Number="(\d)" NumCycles="(\d*?)" IsIndexedRead="([Y|N])"/){

		$read_number=$1;
		$cycles=$2;
		$is_index=$3;

	#MiSeq RunInfo.xml
	} elsif (/<Read NumCycles="(\d*?)" Number="(\d)" IsIndexedRead="([Y|N])"/) {
		
		$read_number=$2;
		$cycles=$1;
		$is_index=$3;

	}

	if($read_number == 1 && $is_index eq "N"){
		$length_read1=$cycles;
	}

	if($read_number == 2 && $is_index eq "N"){
		$length_read2=$cycles;
	}
		
	if($read_number == 2 && $is_index eq "Y"){
		$length_idx_read1=$cycles;
	}
		
	if($read_number == 3 && $is_index eq "N"){
		$length_read2=$cycles;
	}	
		
	if($read_number == 3 && $is_index eq "Y"){
		$length_idx_read2=$cycles;
	}
		
	if($read_number == 4 && $is_index eq "N"){
		$length_read2=$cycles;
	} 
	
}

close(RI);

#print "$length_read1\n";
#print "$length_idx_read1\n";
#print "$length_idx_read2\n";
#print "$length_read2\n";

#parse sample sheet
open(IN, "<$sample_sheet") or die "Unable to open sample sheet $sample_sheet: $!\n";

my $instrument="hiseq";

my $lane_idx = -1;
my $index_idx = -1;
my $index2_idx = -1;

my %lengths_idx1;
my %lengths_idx2;

while(<IN>){

	#go to 'Data' section
	if(/\[Data\]/){
	
		my $header_line = <IN>; 
		chomp($header_line);
				
		#get column indexes
		my @column_names = split(',', $header_line);
		
		
		my $idx = 0;
		foreach my $name (@column_names){
		
			if($name =~ /Lane/){
				$lane_idx=$idx;
			}
		
			if($name =~ /^index$/){
				$index_idx=$idx;
			}
			if($name =~ /index2/){
				$index2_idx=$idx;
			}
			
			$idx++;
		
		}

		if($lane_idx == -1){			
			$instrument="miseq";
		}

		while(<IN>){
		
			chomp;
			my @tokens = split(',');	
			my $token_count=@tokens;
			my $current_lane=1;

			if($instrument eq "hiseq"){
				$current_lane=$tokens[$lane_idx];
			} else {
				$current_lane=1;
			}
		
			if($current_lane == $lane || $instrument eq "miseq"){
					
				#idx1
				if($index_idx != -1 && $tokens[$index_idx] ne ""){
					
					my $seq=$tokens[$index_idx];
					my $length=length($seq);
					$lengths_idx1{$length}="";
					
				}
			
				#idx2
				if($index2_idx != -1 && $tokens[$index2_idx] ne ""){
					
					my $seq=$tokens[$index_idx];
					my $length=length($seq);
					$lengths_idx2{$length}="";
					
				}
		
			}

		} #end of while(<IN>)

	} #end of if(/\[Data\]/)
	
} #end of while(<IN>)

#get lengths of indexes
my @keys_idx1 = sort {$a<=>$b} keys %lengths_idx1;
my @keys_idx2 = sort {$a<=>$b} keys %lengths_idx1;

my $length_idx1 = get_shortest_index_length(\@keys_idx1, 1);
my $length_idx2 = get_shortest_index_length(\@keys_idx1, 2);

sub get_shortest_index_length {

	my $ref_len = shift;
	my @len = @{$ref_len};
	my $idx_no = shift;
	my $retval = -1;

	#get shortest length
	if(@len != 0){
		$retval = $len[0];
	}

	#warn if there are more than one index length
#	if(@len > 1){
#		
#		print "WARNING: Different lengths index $idx_no @len in lane $lane. Shorter index length ($retval) will be used to generate bases mask.\n";
#
#	} 
		
	return $retval;
			 
}

#generate bases mask

#read 1
my $bases_mask="y".($length_read1-1)."n";

#index read 1
if($length_idx_read1 != -1){
	$bases_mask=$bases_mask.",i".$length_idx1;
	for(my $i = 0; $i < $length_idx_read1 - $length_idx1; $i++){
		$bases_mask=$bases_mask."n";
	}
}

#index read 2
if($length_idx_read2 != -1){
	$bases_mask=$bases_mask.",i".$length_idx2;
	for(my $i = 0; $i < $length_idx_read2 - $length_idx2; $i++){
		$bases_mask=$bases_mask."n";
	}
}

#read 2
if($length_read2 != -1){
	$bases_mask=$bases_mask.",y".($length_read2-1)."n";
}

print "$bases_mask\n";

