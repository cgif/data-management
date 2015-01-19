#
# runs rsync on rawdata and results directories on cx1 
# for backup to ax3
#

TODAY=`date +%Y-%m-%d`
NOW="date +%Y-%m-%d%t%T%t"

LOG_DIR=$1
EXCLUDE_FILE=$2

LOG_FILE=$LOG_DIR/rsync.$TODAY.log

#redirect stdout to log file...
exec > $LOG_FILE

#...and stderr to stdout 
exec 2>&1

for PROJECT in `ls --color=never /ax3-cgi/results/ | grep -v 'shared'`
do

    echo "`$NOW`syncing $PROJECT..."	

    #sync rawdata documents
    SOURCE=/groupvol/cgi/rawdata/documents/$PROJECT
    DESTINATION=/ax3-cgi/rawdata/$PROJECT/documents
    mkdir -p $DESTINATION
    
    #if cx1 source exists and is not empty...
    if [[ -d "$SOURCE" ]] &&
       [[ "$(ls -A $SOURCE)" ]]
    then
    
	    echo "`$NOW`syncing $SOURCE..."    
	    # -r recurse into directories
	    # -u skip files that are newer on the receiver
	    # -l copy symlinks
	    # -p preserver permissions
	    # -t preserve modification times
	    # --delete delete extraneous files from destination dirs
	    rsync -rulpt $SOURCE/* $DESTINATION
	
	else
	    echo "`$NOW`$SOURCE does not exist or is empty. Skipped."    		
	fi
	
	#sync results (excluding fastqc and bwa directories)
    SOURCE=/groupvol/cgi/results/$PROJECT
    DESTINATION=/ax3-cgi/results/$PROJECT

    #if cx1 source exists and is not empty...
    if [[ -d "$SOURCE" ]] &&
       [[ "$(ls -A $SOURCE)" ]]
    then

	    echo "`$NOW`syncing $SOURCE..."	
		rsync -rulpt --exclude-from=$EXCLUDE_FILE $SOURCE/* $DESTINATION/

	else
	    echo "`$NOW`$SOURCE does not exist or is empty. Skipped."    		
	fi

	#sync runs (excluding fastqc and bwa directories)
    SOURCE=/groupvol/cgi/runs/$PROJECT
    DESTINATION=/ax3-cgi/runs/$PROJECT/cx1

	mkdir -p $DESTINATION

    #if cx1 source exists and is not empty...
    if [[ -d "$SOURCE" ]] &&
       [[ "$(ls -A $SOURCE)" ]]
    then
       
	    echo "`$NOW`syncing $SOURCE..."	
		rsync -rulpt $SOURCE/* $DESTINATION/

	else
	    echo "`$NOW`$SOURCE does not exist or is empty. Skipped."    		
	fi

	echo "`$NOW`done"
	echo "`$NOW`-------------------------------------------------------"

done;
