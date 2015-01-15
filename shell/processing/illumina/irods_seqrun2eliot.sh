#!/bin/bash

###
#these lines were added for testing because our current run is  already registered in iiRODS and first deleting it from there would take quite a while
#for that reason, i have sought to create 'another run'(copy of the one the one on the directory)
cp -r /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/ /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW
mv /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXX.csv /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
echo -n "" > /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
cat /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/C3YBMACXX.csv | awk 'NR<2{print}' >> /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
cat /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/C3YBMACXX.csv | awk 'BEGIN {FS=","}{if ($3 == "CD12"){print}}' >> /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
cat /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/C3YBMACXX.csv | awk 'BEGIN {FS=","}{if ($3 == "CD36"){print}}' >> /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv




##******Ordinarily, the SCRIPT STARTS FROM HERE*****

#This script runs on orwell, as a cron job
#It checks the 'Seqeuncing-runs-Directory' on orwell and if there are any runs that have been completed but are yet to be processed,
# they are sent to the data handling script.


###


ORWELL_SEQRUNS_DIR=/home/igf/seqrun/illumina
NOW="date +%m/%d/%Y_%H:%M:%S"





#get all the runs in the sequencing-runs-directory
echo "`$NOW` getting runs in $ORWELL_SEQRUNS_DIR..."
DIRECTORY_RUNS=`ls --color=never $ORWELL_SEQRUNS_DIR`

#log into irods with iinit [password]
iinit mmuelle1

#getting runs already registered in iRODS
echo "`$NOW` getting runs already registered in iRODS..."
IRODS_RUNS=`ils | awk 'NR>1 {print $2}' | cut -f5 -d/`		#NR>1 is used to skip the line in irods_ils that shows the collection name/title




#getting unregistered runs
UNREGISTERED_RUNS=${DIRECTORY_RUNS[@]}				# i)first, assume every RUN in the run-directory is unregistered
echo "`$NOW` getting unregistered runs..."								
if [ ${#IRODS_RUNS[@]} -eq 0 ]							
then 
	echo "empty; no runs have been reigstered to irods"
else 
	for run in ${IRODS_RUNS[@]}
	do
			UNREGISTERED_RUNS=("${UNREGISTERED_RUNS[@]/$run}")		# ii) then, sequentially delete those runs which are already registered in iRODS, so that we remain with the unregistered
	done
fi


#of all the unregistered runs, determine those which have completed, and then register them into iRODS
if [ ${#UNREGISTERED_RUNS[@]} -eq 0 ]							
then 
	echo "all runs in the directory have already been reigstered to irods"
	exit;
else
	for run in $UNREGISTERED_RUNS
	do
		#foreach run, check if its run has completed; if 'RTAComplete.txt' has been written. We believe this is the last file to be written in a sequencing RUN directory
		rta_complete_log=$ORWELL_SEQRUNS_DIR/$run/RTAComplete.txt
		if [ -x $rta_complete_log ]				#we check if it exists
		then
			echo "RTA log exists"
			if [ -s $rta_complete_log ]			#we additionally check that it's not empty (it could be created earlier on but only written-to at the end)
			then
				echo "RTA log not empty"
				echo "$run complete; registering run directory into iRODS"

				#send the RUN data for processsing by the data_handling script			
				/home/mkanwagi/irods_rundata_handler.sh $ORWELL_SEQRUNS_DIR/$run
	
			fi
		fi
	done
fi




