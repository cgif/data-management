#!/bin/bash
#This script is called by ir0ds_seqrun2eliot.sh to handle the processing of
#a completed sequencing run.
#
#The script:
# * creates a gzip archive of only those files necessary for fastq file generation
# *	generates an md5 checksum for the archive
# *	registers the archive and md5 file into irods (to register any file the file has to have 'rx' permissions for 'everyone-else')
# * copies the archive to cx1
# * runs an m5sum check 
# * extracts the archive into /project/tgu/rawdata/seqrun
# * starts the BCL-2-CRAM conversion (qbcl2cram script)

NOW="date +%Y-%m-%d%t%T%t"
TODAY=`date +%Y-%m-%d`

INPUT_SEQRUN=$1
IRODS_USER=$2
IRODS_PWD=$3
SSH_USER=$4
BASE_PYTHON_DIR=$5
USE_IRODS=$6
REMOVE_ADAPTORS=$7
REMOVE_BAMS=$8

RUN_NAME=`basename $INPUT_SEQRUN`
PATH_SEQRUNS_DIR=`dirname $INPUT_SEQRUN`

PATH_SEQRUNS_DIR_IRODS=/igfZone/home/$IRODS_USER/seqrun/illumina
RESOURCE=orwellResc

TRANSFER_DIR=/home/igf/transfer
LOG=/home/igf/log/seqrun_processing/$RUN_NAME.log

HOST=login.cx1.hpc.ic.ac.uk
DATA_VOL_IGF=/project/tgu
PATH_BCL2CRAM_SCRIPT=/project/tgu/src/data-management/shell/processing/illumina/qbcl2cram

DEPLOYMENT_HOST=eliot.med.ic.ac.uk
DEPLOYMENT_PATH=/www/html/report/project
CUSTOMERS_FILEPATH=/home/igf/docs/igf/users
CUSTOMERS_RUNS_FILE=customerInfo.csv

# Initialise log file
echo -n "" >> $LOG

# Redirect stdout and stderr to log file
exec > $LOG
exec 2>&1

# Generating tar archive of the files required for BCL-to-fastq conversion:
# * Data directory
# * runParameters.xml
# * RunInfo.xml
# * SampleSheet.csv
# * customerInfo.csv

echo "`$NOW` Processing sequencing run $RUN_NAME..."
WORKING_DIR=$PWD

# Get SampleSheet filename
# HiSeq runs the sample sheet is named after the flowcell -> extract flow cell ID from run name
# MiSeq runs the sample sheet file is names SampleSheet.csv. Miseq run names contain a '-' in the last token.
SAMPLE_SHEET_PREFIX="SampleSheet"

# Create TAR archive of files and folders required for BCL2FASTQ conversion (Data folder, runParameters.xml RunInfo.xml and samplesheet)
echo "`$NOW` Creating TAR archive..."
cd $PATH_SEQRUNS_DIR/$RUN_NAME

# Convert sample sheet & customers info file
dos2unix $SAMPLE_SHEET_PREFIX.csv
dos2unix $CUSTOMERS_FILEPATH/lims_user.csv

# Get project information from Sample sheet (project_tag:username)
echo -n "" > $CUSTOMERS_RUNS_FILE

# Get the position in the sample_sheet of sample_project column
project_position=`cat $SAMPLE_SHEET_PREFIX.csv| grep Sample_Project | awk -F, '{for(i=1;i<=NF;i++){if($i=="Sample_Project")print i;}}'`

# Get the project column from sample sheet
sample_project_col=0
sample_project_col=`grep Sample_Project $SAMPLE_SHEET_PREFIX.csv | awk -F',' -v tag='Sample_Project' '{ for(i=1;i<=NF;i++){if($i ~ tag){print i}}}'`

if [ $sample_project_col -eq 0 ]; then
  echo 'project column not found in samplesheet'
  exit 1
fi

for project_info in `cat $SAMPLE_SHEET_PREFIX.csv |awk -F',' -v col=$sample_project_col 'BEGIN{data=0}{if($0 ~ /^[Data]/){data=1}{ if( data >= 1){ print $col}}}'|grep -v -e "Sample_Project" | sort -u |sed 1d`
do
	project_tag=`echo $project_info|cut -d ':' -f1`
	project_usr=`echo $project_info|cut -d ':' -f2`

	# Get customer information from customer file Perfect Matching!!
	echo -n $project_tag"," >> $CUSTOMERS_RUNS_FILE
	customers_info=`grep -w $project_usr $CUSTOMERS_FILEPATH/lims_user.csv`
	if [[ -z $customers_info ]]; then
		echo "`$NOW` ERROR: customer for project $project_tag is unknown"
		# Send email alert...
		echo -e "subject:Sequencing Run $RUN_NAME Processing Error - customer unknown for project $project_tag. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
		exit 1
	fi
	echo $customers_info >> $CUSTOMERS_RUNS_FILE
done
if [[ ! -e $CUSTOMERS_RUNS_FILE ]]
	then
		echo "`$NOW` ERROR: Required file $CUSTOMERS_RUNS_FILE  missing... aborting"
		# Send email alert...
		echo -e "subject:Sequencing Run $RUN_NAME Processing Error - Missing file\nRequired file $CUSTOMERS_RUNS_FILE missing for sequencing run $RUN_NAME. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
		exit 1
	fi

# Hack for selecting files for transfer stats
RUN_NAME_LIST="${RUN_NAME}_files_md5"
cd $PATH_SEQRUNS_DIR

# Preparing lists of files
find $RUN_NAME/ -type f \
  -not -path "*/Logs/*" \
  -not -path "*/Thumbnail_Images/*" \
  -not -path "*/Config/*" \
  -not -path "*/PeriodicSaveRates/*" \ 
  -not -path "*/Recipe/*" \
  -not -path "*/RTALogs/*" \
  -not -path "*/Images/*" -exec md5sum {} \; > $TRANSFER_DIR/$RUN_NAME_LIST

cd $TRANSFER_DIR

# Create the run-specific directory
PATH_TARGET_DIR=$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME
echo "`$NOW` Creating target directory $PATH_TARGET_DIR on $HOST..."
ssh $SSH_USER@$HOST "mkdir -m 770 -p " $PATH_TARGET_DIR

# Use rsync for file transfer
rsync --exclude Thumbnail_Images \
      --exclude Images \
      --exclude Config \
      --exclude Logs \
      --exclude PeriodicSaveRates \
      --exclude Recipe \
      --exclude RTALogs \
      -aPce ssh $PATH_SEQRUNS_DIR/$RUN_NAME/ $SSH_USER@$HOST:$PATH_TARGET_DIR/

retval=$?
if [ $retval -ne 0 ]; then
  echo "`$NOW` ERROR registering run data in $TRANSFER_DIR/$RUN_NAME
  exit 1
fi

# Transfer the files list to hpc
rsync -aPce ssh $TRANSFER_DIR/$RUN_NAME_LIST $SSH_USER@$HOST:$PATH_TARGET_DIR
retval=$?
if [ $retval -ne 0 ]; then
  echo "`$NOW` ERROR registering md5 file in $TRANSFER_DIR/$RUN_NAME
  exit 1
fi

# Check transferred files
echo -n "`$NOW` Verifying md5 checksum..."
MD5_STATUS=`ssh $SSH_USER@$HOST "cd $PATH_TARGET_DIR; md5sum --quiet -c $RUN_NAME_LIST|wc -l`

if [ $MD5_STATUS -gt 0 ]; then
  echo -e "subject:Sequencing Run $RUN_NAME Processing Error - MD5 check failed\nThe MD5 check for the file transfer of sequencing run $RUN_NAME failed. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
  exit 1
fi

# Mark sequencing run as known
echo $RUN_NAME >> $TRANSFER_DIR/../seqrun/RUN_LIST

# Change to original working dir
cd $WORKING_DIR		
 
# Execute the bcl to cram script
echo "`$NOW` Starting BCL-to-CRAM conversion..."
ssh $SSH_USER@$HOST "source /etc/bashrc; $PATH_BCL2CRAM_SCRIPT -i $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME -t $USE_IRODS -a $REMOVE_ADAPTORS -b $REMOVE_BAMS -p $BASE_PYTHON_DIR"


