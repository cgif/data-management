#!/bin/bash

##******Ordinarily, the SCRIPT STARTS FROM HERE*****

#This script runs on orwell, as a cron job
#It checks the 'Seqeuncing-runs-Directory' on orwell and if there are any runs that have been completed but are yet to be processed,
# they are sent to the data handling script.


###
SKIP=$1
USE_IRODS=$2
REMOVE_ADAPTORS=$3
REMOVE_BAMS=$4

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
PATH_SEQRUNS_DIR=/home/igf/seqrun/illumina
NOW="date +%Y-%m-%d%t%T%t"
IRODS_USER=igf
IRODS_PWD=igf

#SSH_USER=ksannare
SSH_USER=dkaspera

if [ "$SKIP" = "T" ]
then
        echo "Skipping processing run ...."
        exit 0
fi

#get all the runs in the sequencing-runs-directory
#echo "`$NOW` getting runs in $PATH_SEQRUNS_DIR..."
RUNS=`ls --color=never $PATH_SEQRUNS_DIR`


#log into irods with iinit [password]
#iinit $IRODS_PWD

#getting runs already registered in iRODS
echo "`$NOW` getting runs already registered in iRODS..."
IRODS_RUNS=`ils | awk 'NR>1 {print $2}' | cut -f5 -d/`		#NR>1 is used to skip the line in irods_ils that shows the collection name/title
#NR>1 is used to skip the line in irods_ils that shows the collection name/title
#echo "`$NOW` getting runs already registered in iRODS..."

if [ "$USE_IRODS" = "T" ]
then
	REGISTERED_RUNS=`ils seqrun/illumina | awk 'NR>1 {print $2}' | cut -f7 -d/`		
	## checks if there was an error on irods
	if [ "$REGISTERED_RUNS" = "" ]; then
    		echo "`$NOW` ERROR reading registered runs in IRODS"
    	exit 1
	fi
else
	REGISTERED_RUNS=`cat $PATH_SEQRUNS_DIR/../RUN_LIST`
fi


#getting unregistered runs
UNREGISTERED_RUNS=${RUNS[@]}		

#echo "`$NOW` getting unregistered runs..."								
if [ ${#REGISTERED_RUNS[@]} -eq 0 ]							
then

	#do nothing
	echo -n ""

else 
	
	#delete runs already registered in iRODS
	for RUN in ${REGISTERED_RUNS[@]}
	do
			echo $RUN
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
		if [ -x $RTA_COMPLETE_LOG ]
		then
		
			#...if it exists make sure it is not empty...
			if [ -s $RTA_COMPLETE_LOG ]
			then
			
				#... and start run processing
				echo "`$NOW` Run $RUN complete. Starting processing..."
				echo "`$NOW` $BASEDIR/irods_rundata_handler.sh $PATH_SEQRUNS_DIR/$RUN $IRODS_USER $IRODS_PWD $SSH_USER $USE_IRODS $REMOVE_ADAPTORS $REMOVE_BAMS"
				$BASEDIR/irods_rundata_handler.sh $PATH_SEQRUNS_DIR/$RUN $IRODS_USER $IRODS_PWD $SSH_USER $USE_IRODS $REMOVE_ADAPTORS $REMOVE_BAMS
	
			fi
		fi
	done
	
fi

