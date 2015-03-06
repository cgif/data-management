#!/bin/bash

###
#these lines were added for testing because our current run is  already registered in iiRODS and first deleting it from there would take quite a while
#for that reason, i have sought to create 'another run'(copy of the one the one on the directory)
#cp -r /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/ /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW
#mv /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXX.csv /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
#echo -n "" > /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
#cat /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/C3YBMACXX.csv | awk 'NR<2{print}' >> /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
#cat /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/C3YBMACXX.csv | awk 'BEGIN {FS=","}{if ($3 == "CD12"){print}}' >> /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv
#cat /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXX/C3YBMACXX.csv | awk 'BEGIN {FS=","}{if ($3 == "CD36"){print}}' >> /home/igf/seqrun/illumina/140530_SN674_0277_BC3YBMACXW/C3YBMACXW.csv




##******Ordinarily, the SCRIPT STARTS FROM HERE*****

#This script runs on orwell, as a cron job
#It checks the 'Seqeuncing-runs-Directory' on orwell and if there are any runs that have been completed but are yet to be processed,
# they are sent to the data handling script.


###

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
PATH_SEQRUNS_DIR=/home/igf/seqrun/illumina
NOW="date +%Y-%m-%d%t%T%t"

#get all the runs in the sequencing-runs-directory
#echo "`$NOW` getting runs in $PATH_SEQRUNS_DIR..."
DIRECTORY_RUNS=`ls --color=never $PATH_SEQRUNS_DIR`

#log into irods with iinit [password]
iinit mmuelle1

#getting runs already registered in iRODS
#NR>1 is used to skip the line in irods_ils that shows the collection name/title
#echo "`$NOW` getting runs already registered in iRODS..."
IRODS_RUNS=`ils | awk 'NR>1 {print $2}' | cut -f5 -d/`		

#getting unregistered runs
UNREGISTERED_RUNS=${DIRECTORY_RUNS[@]}				
#echo "`$NOW` getting unregistered runs..."								
if [ ${#IRODS_RUNS[@]} -eq 0 ]							
then

	#do nothing
	echo -n ""

else 
	
	#delete runs already registered in iRODS
	for RUN in ${IRODS_RUNS[@]}
	do
			UNREGISTERED_RUNS=("${UNREGISTERED_RUNS[@]/$RUN}")		# ii) then, 
	done
	
fi


#of all the unregistered runs, determine those which have completed, and then register them into iRODS
if [ ${#UNREGISTERED_RUNS[@]} -eq 0 ]							
then 

	#do nothing
	echo -n ""
	exit 0;
	
else

	for RUN in $UNREGISTERED_RUNS
	do
		#for each run, check if its run has completed...
		#check for presence of 'RTAComplete.txt'...
		RTA_COMPLETE_LOG=$PATH_SEQRUNS_DIR/$RUN/RTAComplete.txt
		if [ -x $RTA_COMPLETE_LOG ]				#we check if it exists
		then
		
			#...if it exists make sure it is not empty
			if [ -s $RTA_COMPLETE_LOG ]
			then
			
				#register in iRODS
				echo "`$NOW` Run $RUN complete. Starting processing..."
				echo "`$NOW` $BASEDIR/irods_rundata_handler.sh $PATH_SEQRUNS_DIR/$RUN"
	
			fi
		fi
	done
fi




