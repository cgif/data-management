#!/bin/bash



SEQRUNS_DIR=/home/igf/seqrun/illumina
DATA_VOL_IGF=/project/tgu

runs_info_file=/home/igf/seqrun/run_db.txt

#remove if run as cron job
#echo -e "run_id\trun_start_time\trun_end_time\ttransfer_start_time\ttransfer_end_time\tconversion_start_time\tconversion_end_time\t" > $runs_info_file







#get all runs in the directory
echo "getting runs in $SEQRUNS_DIR..."
DIRECTORY_RUNS=`ls --color=never $SEQRUNS_DIR`


#get all runs in the runs_info file
echo "getting recorded runs from $runs_info_file...." 
RECORDED_RUNS=`sed 1d $runs_info_file | cut -f1`
	

#getting the runs that are yet to be written to the the runs_info file (unrecorded runs)
unrecorded_run_ids=${DIRECTORY_RUNS[@]}							#First, get all the runs in the directory
									
								
echo "determining new runs..."								
if [ ${#RECORDED_RUNS[@]} -eq 0 ]							
then 
	echo empty
else 

	for run in ${RECORDED_RUNS[@]}							# From all the runs in the directory (see step above),	
	do
			unrecorded_run_ids=("${unrecorded_run_ids[@]/$run}")		#   sequentially delete those which are already recorded in the runs_info file		
	done
fi




#write the unrecorded runs to the runs_info file
echo "recording new runs..."
for run in ${unrecorded_run_ids[@]}
do

	#get the run's start time to write it next to its run's id; 	'time-style' is for consistency of the time format in the runs_info file
	start_time=`ls -l --color=never --time-style='+%m/%d/%Y_%H:%M:%S' /home/igf/seqrun/illumina/ | awk -v run="$run" '{if ($7 == run){ print $6}}'`
	
	echo -e "$run\t$start_time\t.\t.\t.\t.\t." >> $runs_info_file

done
	

echo "checking new runs for completion..."

#check for runs which haven't been completed
incomplete_runs=`awk '{if ($3 == "."){ print $1 }}' $runs_info_file | cut -f1`

for run in $incomplete_runs
do
	echo $run
	rta_complete_log=$SEQRUNS_DIR/$run/RTAComplete.txt
	#foreach run, check if its run has completed
	if [ -x $rta_complete_log ]
	then
		echo "RTA log exists"
		if [ -s $rta_complete_log ]
		then
			echo "RTA log not empty"
			echo "$run complete"
			date=`cut -f1 -d ',' $rta_complete_log`
			time=`cut -f2 -d ',' $rta_complete_log | awk 'BEGIN {FS="."} {print $1}'`
			end_time="$date""_""$time"

			#then write the run end_time to the runs_info file, and then send this run to the script that handles the data
		
			#write end_time to file
			/home/mkanwagi/testperl.pl $run run_end_time $end_time $runs_info_file > $runs_info_file.new && mv $runs_info_file.new $runs_info_file
			echo "transfering run for conversion...."
			#send file to the data-handling script
			/home/mkanwagi/rundata_handler.sh $SEQRUNS_DIR/$run
		fi

	fi

done


