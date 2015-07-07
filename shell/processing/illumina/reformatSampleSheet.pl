#!/usr/bin/perl

use strict;
use warnings;

my $input_sample_sheet=$ARGV[0];
my $output_sample_sheet=$ARGV[1];
my $flowcell_id="";
my $index1_length=-1;
my $index2_length=-1;

#convert sample sheet
open(IN, "<$input_sample_sheet") or die "Unable to open input sample sheet $input_sample_sheet: $!\n";
open(OUT, ">$output_sample_sheet") or die "Unable to open output sample sheet $output_sample_sheet: $!\n";


my $instrument="hiseq";
my $operator = "";

while(<IN>){

	if(/Investigator Name/){
		my @tokens = split(',',$_);
		$operator = $tokens[1];
	}

	if(/\[Data\]/){
	
		my $header_line = <IN>; 
		chomp($header_line);
				
		#get column indexes
		my @column_names = split(',', $header_line);
		
		my $lane_idx = -1;
		my $sample_id_idx = -1;
		my $sample_name_idx = -1;
		my $i7_index_id_idx	= -1;
		my $index_idx = -1;
		my $i5_index_id_idx	= -1;
		my $index2_idx = -1;
		my $sample_project_idx = -1;
		my $description_idx = -1;

		my $idx = 0;
		foreach my $name (@column_names){
		
			if($name =~ /Lane/){
				$lane_idx=$idx;
			}
		
			if($name =~ /Sample_ID/){
				$sample_id_idx=$idx;
			}
			
			if($name =~ /Sample_Name/){
				$sample_name_idx=$idx;
			}
			
			if($name =~ /I7_Index_ID/){
				$i7_index_id_idx=$idx;
			}
			
			if($name =~ /^index$/){
				$index_idx=$idx;
			}
			
			if($name =~ /I5_Index_ID/){
				$i5_index_id_idx=$idx;
			}
			
			if($name =~ /index2/){
				$index2_idx=$idx;
			}
			
			if($name =~ /Sample_Project/){
				$sample_project_idx=$idx;
			}
			
			if($name =~ /Description/){
				$description_idx=$idx
			}
			
			$idx++;
		
		}
			
			
		#determine instrument type 	
		if($lane_idx == -1){			
			$instrument="miseq";
		}

		#output format
		#FCID	Lane	SampleID	SampleRef	Index	Description	Control	Recipe	Operator	SampleProject
#		print "Lane: $lane_idx\n";
#		print "SampleID: $sample_id_idx\n";
#		print "SampleRef: $description_idx\n";
#		print "Index: $index_idx - $index2_idx\n";
#		print "Description: $sample_name_idx\n";
#		print "SampleProject: $sample_project_idx\n";
		
		#print header
		print OUT "FCID,Lane,SampleID,SampleRef,Index,Description,Control,Recipe,Operator,SampleProject\n";
#			print "$description_idx\n";
		while(<IN>){
		
			chomp;
			my @tokens = split(',');	

			my $token_count=@tokens;
#			print "$token_count\n";
#			print $tokens[$description_idx]."\n";

			#FCID
			print OUT "$flowcell_id,";
			#Lane
			if($instrument eq "miseq"){
				print OUT "1,";
			} else {
				print OUT $tokens[$lane_idx].",";
			}
			#SampleID
			print OUT $tokens[$sample_id_idx].",";
			#SampleRef
#			my $sample_ref=$tokens[$description_idx];
#			$sample_ref=~s/\n//;
			print OUT $tokens[$description_idx].",";
			#Index
			if($index2_idx != -1 && $tokens[$index2_idx] ne ""){
				my $index1_seq = $tokens[$index_idx];
				my $index2_seq = $tokens[$index2_idx];
				print OUT $index1_seq."-".$index2_seq.",";
			} else {			
				my $index1_seq=$tokens[$index_idx];
				print OUT $index1_seq.",";
			}
			#Description
			print OUT $tokens[$sample_name_idx].",";
			#Control
			print OUT ",";
			#Recipe
			print OUT ",";
			#Operator
			print OUT $operator.",";
			#SampleProject
		        my @column_project = split(':', $tokens[$sample_project_idx]);	
#			print "SampleProject: $column_project[0]\n";
			print OUT $column_project[0]."\n";
		
		}
				
	}
 

}

close(IN);
close(OUT);


