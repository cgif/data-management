#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use File::Basename;
use Getopt::Long qw(GetOptions);
my $script_name='serp.pl';
$main::VERSION="1.0";
my $INPUT_SEQ_RUN="#inputSeqRun";
my $RUN_DATE="#runDate";
my $SINGLE_READ = '#singleRead';
GetOptions('s|singleRead=s' => \$SINGLE_READ,
	   'i|input=s'  => \$INPUT_SEQ_RUN,
	   'r|rdate=s'  => \$RUN_DATE
	) or die "Usage: $0 --single F|T --input <input_seq_run> --rdate <run_date>\n";

VERSION_MESSAGE();

if (!($INPUT_SEQ_RUN && $RUN_DATE)) {
    print "Usage: $0 --singleRead F|T --input <input_seq_run> --rdate <run_date>\n";
    exit 1
}

my $DATA_IGF="/project/tgu";
my $SEQRUN_NAME=basename($INPUT_SEQ_RUN);
#print "SEQRUN_NAME= $SEQRUN_NAME\n";
my $PATH_SEQRUNS_DIR=dirname($INPUT_SEQ_RUN);
#print "PATH_SEQRUNS_DIR= $PATH_SEQRUNS_DIR\n";

#Calculate FLOWCELL_ID 
my @tokens=();
@tokens = split('_', $SEQRUN_NAME);
if(!($tokens[3] =~ /-/)){ 
	$tokens[3]=~s/^[AB]//; 
}
my $FLOWCELL_ID=$tokens[3];

my $PATH_RUN_DIR_BCL2FASTQ=$DATA_IGF."/runs/seqrun/".$SEQRUN_NAME."/bcl2fastq/".$RUN_DATE;
my $PATH_SAMPLE_SHEET_REFORMATTED=$PATH_RUN_DIR_BCL2FASTQ."/".$FLOWCELL_ID.".csv";
my $RUN_SEQDATE="";
while ($tokens[0] =~ /(\d{2})(\d{2})(\d{2})/g) {
	 $RUN_SEQDATE= "20$1-$2-$3"; 
 
}
#print $RUN_SEQDATE;
#print $PATH_SAMPLE_SHEET_REFORMATTED;

if (!(-e $PATH_SAMPLE_SHEET_REFORMATTED)) {
	traceMessage("ERROR", "Sample Sheet $PATH_SAMPLE_SHEET_REFORMATTED does not exists!");
	exit 1;
}


my @insert_col_users=('userName', 'surname', 'name', 'account', 'userPasswd', 'email', 'enabled', 'accountNotExpired', 'credentialNotExpired', 'accountNotLocked');
my @insert_col_rolesusers=('roles_roleId', 'users_userName');
my @insert_col_usersprojects=('id_project', 'id_user');
my @insert_col_error_run=('id_run', 'error_desc');
my @insert_col_run=('run_name', 'run_desc', 'run_date');
my @insert_col_project=('project_tag', 'contact');
my @insert_col_project_run=('id_project', 'disseminated', 'id_run');
my @insert_col_sample=('id_igf', 'id_customer', 'id_project', 'id_run', 'lane', 'expected_n_reads', 'barcode', 'specie', 'sequence_type', 'assembly', 'adaptor');
my @insert_col_fastqc=('id_project','id_run','fastqc_run_date','fastqc_filename','nread', 'lane','sample_name', 'total_sequences_r','sequences_flagged_r','sequence_length', 'gc_r','basic_statistics', 'per_base_sequence_quality','per_tile_sequence_quality','per_sequence_quality_scores', 'per_base_sequence_content', 'per_sequence_gc_content','per_base_N_content','sequence_length_distribution','sequence_duplication_levels','overrepresented_sequences','adapter_content','kmer_content');
my $TABLE_NAME='';
my @insert_val=();
my @what=();
my @where=();
my @values=();
my $run_id = "";
my $lane = "";
my $sample = "";
my $mapping_info= "";
my $index = "";
my $sample_cust= "";
my $project_name = ""; 
my $project_id = ""; 
my $user_id = ""; 
my @fastqc=();
my @error_str=();


##### processes formatted simple sheet
open (DATA, "$PATH_SAMPLE_SHEET_REFORMATTED")||traceMessage("ERROR", "Cannot open Sample Sheet $PATH_SAMPLE_SHEET_REFORMATTED");
traceMessage("INFORM", "Begin Statistics Collection");
my $dbh = open_connection();
# Store the RUN information
$TABLE_NAME = 'runs';
@insert_val=($SEQRUN_NAME,'TEST',$RUN_DATE);
$run_id = insertInDB($TABLE_NAME, \@insert_col_run, \@insert_val);
traceMessage('INFORM','Insert in run table');
my $first = 1;
while (<DATA>){
	if( $first ) {
           $first = 0;
       	} else {        
		(undef, $lane, $sample, $mapping_info, $index, $sample_cust, undef, undef, undef, $project_name) = split(',');
		my ($specie, $assembly, $sequence_type, $adaptor, $expected_n_reads) = split(':', $mapping_info);

		chomp($lane);
		chomp($sample);
		chomp($index);
		chomp($sample_cust);
		chomp($project_name);
		chomp($specie);
		chomp($assembly);
		chomp($sequence_type);
		chomp($adaptor);
		chomp($expected_n_reads);
		$TABLE_NAME = 'projects';
		@what=('id');
		@where=('project_tag');
		@values=($project_name);
		$project_id = selectInDB($TABLE_NAME, \@what, \@where, \@values);
		if (!$project_id){
			@insert_val=($project_name, "TEST");
        		traceMessage('INFORM','Insert in project table');
			$project_id = insertInDB($TABLE_NAME, \@insert_col_project,\@insert_val);
		}
		$TABLE_NAME = 'projects_runs';
		@what=('id_run');
		@where=('id_project', 'id_run');
		@values=($project_id, $run_id);
		my $id = selectInDB($TABLE_NAME, \@what, \@where, \@values);

	        if(!$id){
			$TABLE_NAME = 'projects_runs';
			@insert_val=($project_id, 'Y', $run_id);
        		traceMessage('INFORM','Insert in project_run table');
			insertInDB($TABLE_NAME, \@insert_col_project_run,\@insert_val);
		}	

        	traceMessage('INFORM','Check if he is new Customer to add');
		checkCustomer($project_name);
		
		
        	traceMessage('INFORM','Insert in Sample table');
		$TABLE_NAME = 'samples';	
		@insert_val=($sample,  $sample_cust, $project_id, $run_id, $lane, $expected_n_reads, $index, $specie, $sequence_type, $assembly, $adaptor);
		insertInDB($TABLE_NAME, \@insert_col_sample,\@insert_val);
		
		my $fastqc_r=$DATA_IGF."/results/".$project_name."/fastqc/".$RUN_SEQDATE."/".$sample."/".$SEQRUN_NAME."_".$index."_L00".$lane."_R1_001_fastqc";
		if (!(-d $fastqc_r)) {
        		traceMessage("ERROR", "FastQC report $fastqc_r does not exists!");
			@error_str=($run_id,'Directory '.$fastqc_r.' does not exists');
			traceErrorInDB('errors_runs',\@insert_col_error_run,\@error_str);
		}else {		
			@fastqc=($project_id, $run_id, $RUN_SEQDATE, $fastqc_r, 1, $lane, $sample);
			@fastqc = parseFastQCReport($fastqc_r,\@fastqc);
			if($#fastqc == $#insert_col_fastqc) {
				$TABLE_NAME = 'fastqcs';
        			traceMessage('INFORM','Insert in FastQC table');
				insertInDB($TABLE_NAME, \@insert_col_fastqc,\@fastqc);
			}
		}
		if($SINGLE_READ eq 'F'){
			$fastqc_r=$DATA_IGF."/results/".$project_name."/fastqc/".$RUN_SEQDATE."/".$sample."/".$SEQRUN_NAME."_".$index."_L00".$lane."_R2_001_fastqc";
			if (!(-d $fastqc_r)) {
				@error_str=($run_id,'Directory '.$fastqc_r.' does not exists');
        			traceMessage("ERROR", "FastQC report $fastqc_r does not exists!");
				traceErrorInDB('errors_runs',\@insert_col_error_run,\@error_str);
			}else {		
				@fastqc=($project_id, $run_id, $RUN_SEQDATE, $fastqc_r, 2, $lane, $sample);
				@fastqc = parseFastQCReport($fastqc_r,\@fastqc);
				if($#fastqc == $#insert_col_fastqc) {
					$TABLE_NAME = 'fastqcs';
        				traceMessage('INFORM','Insert in FastQC table');
					insertInDB($TABLE_NAME, \@insert_col_fastqc,\@fastqc);
				}
			}
		}
	}
}
close(DATA);
$dbh->commit();
close_connection($dbh);
traceMessage("INFORM", "End Statistics Collection");

	


####################
# ROUTINE to trace #
####################
sub traceMessage
{

	my ($traceLevel, $message) = @_;
	my ($traceMessage, $line, $sec, $min, $hour, $day, $mon, $year);
	(undef, undef, $line) = caller ();

	($sec, $min, $hour, $day, $mon, $year) = localtime(time());

	$traceMessage = sprintf("%.10s%s:%04d:%02d/%02d/%02d/ %02d:%02d:%02d > %s\n",
                        	$traceLevel.'----------',
				" serp.pl ",
                                $line,
                                $day,
                                $mon+1,
                                $year%100,
                                $hour,
                                $min,
                                $sec,
                                $message);
	warn ($traceMessage);
}

###################
# VERSION MESSAGE #
###################
sub VERSION_MESSAGE {
	print "$script_name $main::VERSION - by Massimiliano Cosso (Imperial College 2016)\n\n";
}


#############################
# Open Database Connection  # 
#############################
sub open_connection {
	my $dbhandler = DBI->connect("DBI:mysql:database=serpDB;host=eliot.med.ic.ac.uk", "igf", "igf", {RaiseError => 1, PrintError => 0, AutoCommit=>0 });
	return $dbhandler;
}

#############################
# Close Database Connection #
#############################  
sub close_connection {
	my $dbh = $_[0];
	$dbh->disconnect;	
	
}

##############
# selectInDB #
##############
sub selectInDB {
	
	my $table = $_[0];
	my @mywhat = @{$_[1]};
	my @mywhere = @{$_[2]};
	my @myvalue = @{$_[3]};

	#my $dbhandler = open_connection();
	my $query = "select ".join(",", @mywhat)." from ". $table." where ".join(" =? and ", @mywhere)." =? and 1=1";
	traceMessage('INFORM',$query);	
	#my $query = " select id from $table where $where = ? ";
	my $sth = $dbh->prepare_cached($query);
	my $nvalue=0;
	traceMessage('INFORM','WHERE ARRAY LENGTH '.$#mywhere);
	while ($nvalue <= $#mywhere){
		$sth->bind_param( $nvalue+1, $myvalue[$nvalue]);
		$nvalue++;
	} 
	$sth->execute();
	my $id = $sth->fetchrow();
	$sth->finish;
	traceMessage('INFORM','ID '.$id);	
	#close_connection($dbhandler);
  	return $id;
}

#####################
# trace error In DB #
#####################
sub traceErrorInDB {
	my $table = $_[0];
	my @colums = @{$_[1]};
	my @values = @{$_[2]};

	#traceMessage('INFORM','Open Database Connection');	
	#my $dbh = open_connection();
	my $query = "insert into $table (". join(",", @colums).") values (". join(",", ("?") x @colums).")";

	traceMessage('INFORM',$query);	
	my $valori ="(" .join(",", @values).")"; 	
	traceMessage('INFORM',$valori);	

        my $sth = $dbh->prepare_cached($query);
      	$sth->execute(@values);
	if ( $sth->err ) {
		traceMessage('ERROR','insert '.$table.' '.$valori);
	}
	
	#close_connection($dbh);
}

#	/* traceErrorInDB('error_run',$run_id,'insert into '.$table.' '.$valori); */
################
# Insert In DB #
################
sub insertInDB {
	my $table = $_[0];
	my @colums = @{$_[1]};
	my @values = @{$_[2]};

	#traceMessage('INFORM','Open Database Connection');	
	#my $dbh = open_connection();
	my $query = "insert into $table (". join(",", @colums).") values (". join(",", ("?") x @colums).")";

	traceMessage('INFORM',$query);	
	my $valori ="(" .join(",", @values).")"; 	
	traceMessage('INFORM',$valori);	

        my $sth = $dbh->prepare_cached($query);
	if ($sth->err) {		
		traceMessage('ERROR','insert '.$table.' '.$valori);
	}
	
      	$sth->execute(@values);
	if ($sth->errstr) {		
		traceMessage('ERROR','insert '.$table.' '.$valori);
	}
	
 	my $my_project_id = $sth->{ mysql_insertid };
	#close_connection($dbh);
	#traceMessage('INFORM','Close Database Connection');	
	return $my_project_id;
}

########################
#  parse FastQC report #
########################
sub parseFastQCReport {
	my $pathFastqc = $_[0];
	my @fastqc = @{$_[1]};
	my $fastqc_data = 'fastqc_data.txt';
	my $summary = 'summary.txt';

	my $filename = $pathFastqc."/".$fastqc_data;
	my @error_str=($run_id,'Cannot open Fastqc Report '.$filename);
	#open (FASTQCDATA, "$filename")||traceMessage("ERROR", "Cannot open Fastqc Report $filename");traceErrorInDB('error_run',\@insert_col_error_run,\@error_str);
	open (FASTQCDATA, "$filename")||traceErrorInDB('errors_runs',\@insert_col_error_run,\@error_str);
	while (<FASTQCDATA>){
		my $f1 = 1 if /^Total Sequences/;
		if ($f1 && /^\S+\ \S+\t(\d+)/){
			push(@fastqc, $1);
			$f1=0;
		}
		my $f2 = 1 if /^Sequences flagged as poor quality/;
		if ($f2 && /^\S+\ \S+\ \S+\ \S+\ \S+\t(\d+)/){
			push(@fastqc, $1);
			$f2=0;
		}
		my $f3 = 1 if /^Sequence length/;
		if ($f3 && /^\S+\ \S+\t(\d+)/){
			push(@fastqc, $1);
			$f3=0;
		}
		my $f4 = 1 if /^%GC/;
		if ($f4 && /^\S+\t(\d+)/){
			push(@fastqc, $1);
			$f4=0;
		}
	}
	close(FASTQCDATA);

	$filename = $pathFastqc."/".$summary;
	@error_str=($run_id,'Cannot open Summary Report '.$filename);
	#open (SUMMARY, "$filename")||traceMessage("ERROR", "Cannot open Summary Report $filename");traceErrorInDB('error_run',\@insert_col_error_run,\@error_str);
	open (SUMMARY, "$filename")||traceErrorInDB('errors_runs',\@insert_col_error_run,\@error_str);
	while (<SUMMARY>){
		my ($value, undef, undef) = split('\t');
		push(@fastqc, $value);
	}
	close(SUMMARY);
	return @fastqc;
}

######################################################
#  check if the customer is in DB otherwise Add him  #
######################################################
sub checkCustomer {
	my $project_tag = $_[0];
	my $customer_email=$PATH_RUN_DIR_BCL2FASTQ."/customer_mail.".$project_tag;

	open (CUSTOMER, "$customer_email")||traceMessage("ERROR", "Cannot open Customer email $customer_email");
	my $firstUn = 1;
	my $firstP = 1;
	my $email = "";
	my $name = "";
	my $surname = "";
	my $username = "";
	my $password = undef;
	while (<CUSTOMER>){
       		my $f1=1 if /^To:/;
       		if ($f1 && /^\S+\ (\S+)/){
        		$email = $1;
       	        	$f1=0;
       	 	}
       	 	my $f2=1 if /^Dear/;
       	 	if ($f2 && /^\S+\ (\S+)\ (\S+),/){
        		$name = $1;
        		$surname = $1;
       	         	$f2=0;
       	 	}
       	 	my $f3=1 if /^User Name:/;
       	 	if ($f3 && $firstUn && /^\S+\ \S+\ (\S+)/){
        		$username = $1;
       	         	$f3=0;
       	         	$firstUn=0;
       	 	}
       	 	my $f4=1 if /^Password:/;
       	 	if ($f4 && $firstP && /^\S+\ (\S+)/){
        		$password = $1;
       	         	$f4=0;
       	         	$firstP=0;
       	 	}
	}
	close(CUSTOMER);
	# checks if the user is already into the db
	$TABLE_NAME = 'users';
        @what=('userName');
        @where=('userName');
        @values=($username);
        $user_id = selectInDB($TABLE_NAME, \@what, \@where, \@values);
        if (!$user_id){
		# new user
        	@insert_val=($username, $surname, $name, "", $password, $email, 1, 1, 1, 1 );
                traceMessage('INFORM','Insert in users table');
                $user_id = insertInDB($TABLE_NAME, \@insert_col_users,\@insert_val);
		$TABLE_NAME = 'rolesusers';
		@insert_val=("ROLE_BCRSI", $username);
                traceMessage('INFORM','Insert in rolesusers table');
                $user_id = insertInDB($TABLE_NAME, \@insert_col_rolesusers,\@insert_val);
        }
	# checks if the user is already linked to the projects 
	$TABLE_NAME = 'projects_users';
	@what=('id_project');
	@where=('id_project','id_user');
        @values=($project_id, $username);
        $user_id = selectInDB($TABLE_NAME, \@what, \@where, \@values);
	if (!$user_id){
		# user is not linked to the projects 
		@insert_val=($project_id, $username);
        	traceMessage('INFORM','Insert in projects_users table');
		$user_id = insertInDB($TABLE_NAME, \@insert_col_usersprojects,\@insert_val);
	}

}
exit;

