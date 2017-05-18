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
SLACK_TOKEN=$9

RUN_NAME=`basename $INPUT_SEQRUN`
PATH_SEQRUNS_DIR=`dirname $INPUT_SEQRUN`

PATH_SEQRUNS_DIR_IRODS=/igfZone/home/$IRODS_USER/seqrun/illumina
RESOURCE=orwellResc

TRANSFER_DIR=/home/igf/transfer
LOG=/home/igf/log/seqrun_processing/$RUN_NAME.log

HOST=login.cx1.hpc.ic.ac.uk
DATA_VOL_IGF=/project/tgu
PATH_BCL2CRAM_SCRIPT=/work/adatta17/git_repo/data-management/shell/processing/illumina/qbcl2cram

DEPLOYMENT_HOST=eliot.med.ic.ac.uk
DEPLOYMENT_PATH=/www/html/report/project
CUSTOMERS_FILEPATH=/home/igf/docs/igf/users
CUSTOMERS_RUNS_FILE=customerInfo.csv

SLACK_URL=https://slack.com/api/chat.postMessage
SLACK_OPT="-d 'channel'='C4W5G8550' -d 'username'='igf_bot'"

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
  msg="project column not found in samplesheet for run $RUN_NAME"
  echo $msg
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
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
                msg="subject:Sequencing Run $RUN_NAME Processing Error - customer unknown for project $project_tag. Processing aborted."
                res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
		exit 1
	fi
	echo $customers_info >> $CUSTOMERS_RUNS_FILE

        ## Create IRODS account
        customers_info_row=`grep -w $project_tag $CUSTOMERS_RUNS_FILE`
        customer_name=`echo $customers_info_row|cut -d ',' -f2`
        customer_username=`echo $customers_info_row|cut -d ',' -f3`
        customer_passwd=`echo $customers_info_row|cut -d ',' -f4`
        customer_email=`echo $customers_info_row|cut -d ',' -f5`

        if [[ $customer_email != *"@"* ]]; then
          msg="Sequencing Run $SEQ_RUN_NAME Deploying Error - the email address for $customer_username is unknown, $customer_email"
          res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
          exit 1
        fi

        # Check for non-hpc users
        ldapUser=`ssh $SSH_USER@$HOST "ldapsearch -x -h unixldap.cc.ic.ac.uk | grep uid:|grep -w $customer_username|wc -l"`

        if [ "$ldapUser" -eq 0 ]; then
          msg="customer $customer_username dosn't have hpc access"
          res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
          externalUser="Y"
        fi
        
        irods_user=`iadmin lu | grep $customer_username | cut -d "#" -f1`

        if [ "$irods_user" == "" ]; then
          iadmin mkuser $customer_username#igfZone rodsuser
          if [ "$?" -ne 0 ]; then
            msg="ERROR: can not create irods user $customer_username , aborting process." 
            res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
            exit 1
          fi

          msg="customer account for $customer_username is created in irods for project $project_tag "
          res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh` 

          if [ "$externalUser" == "Y" ]; then
            iadmin moduser $customer_username#igfZone password $customer_passwd          

            msg="password has been set for non-hpc customer account $customer_username"
            res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh` 
          fi

          ichmod -M own igf /igfZone/home/$customer_username
          ichmod -r inherit /igfZone/home/$customer_username
        fi
done

if [[ ! -e $CUSTOMERS_RUNS_FILE ]]
	then
                msg="Sequencing Run $RUN_NAME Processing Error - Missing file\nRequired file $CUSTOMERS_RUNS_FILE missing for sequencing run $RUN_NAME. Processing aborted."
                res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
		exit 1
	fi

# Hack for selecting files for transfer stats
RUN_NAME_LIST="${RUN_NAME}_files_md5"
cd $PATH_SEQRUNS_DIR/$RUN_NAME

msg="changing to $PATH_SEQRUNS_DIR/$RUN_NAME"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

# Preparing lists of files
find . -type f -not -path "*/Logs/*" -not -path "*/Thumbnail_Images/*" -not -path "*/Config/*" -not -path "*/PeriodicSaveRates/*" -not -path "*/Recipe/*" -not -path "*/RTALogs/*" -not -path "*/Images/*" -exec md5sum {} \; > $TRANSFER_DIR/$RUN_NAME_LIST

retval=$?
if [ "$retval" -ne 0 ]; then
  msg="got error while running md5 generation for $RUN_NAME"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
fi

if [ ! -s $TRANSFER_DIR/$RUN_NAME_LIST ]; then
  msg="md5 file for run $RUN_NAME is empty, aporting process"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi

cd $TRANSFER_DIR

# Create the run-specific directory
PATH_TARGET_DIR=$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME

msg="Creating target directory $PATH_TARGET_DIR on $HOST"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

ssh $SSH_USER@$HOST "mkdir -m 770 -p " $PATH_TARGET_DIR

# Use rsync for file transfer
msg="Start transferring files from Orwell for run $RUN_NAME"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

rsync --exclude Thumbnail_Images \
      --exclude Images \
      --exclude Config \
      --exclude Logs \
      --exclude PeriodicSaveRates \
      --exclude Recipe \
      --exclude RTALogs \
      -aPce ssh $PATH_SEQRUNS_DIR/$RUN_NAME/ $SSH_USER@$HOST:$PATH_TARGET_DIR/

retval=$?
if [ "$retval" -ne 0 ]; then
  msg="`$NOW` ERROR registering run data in $TRANSFER_DIR/$RUN_NAME"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi

msg="finished data transfer for run $RUN_NAME"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

# Transfer the files list to hpc
rsync -aPce ssh $TRANSFER_DIR/$RUN_NAME_LIST $SSH_USER@$HOST:$PATH_TARGET_DIR
retval=$?
if [ "$retval" -ne 0 ]; then
  msg="`$NOW` ERROR registering md5 file in $TRANSFER_DIR/$RUN_NAME"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi

md5_val=`ssh $SSH_USER@$HOST "wc -l $PATH_TARGET_DIR/$RUN_NAME_LIST|cut -f1 -d' '"`

if [ "$md5_val" -eq 0 ]; then
  msg="Sequencing Run $RUN_NAME Processing Error, no entry present in the md5 list. Processing aborted."
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi


# Check transferred files, need to convert it to queue job
RUN_NAME_CHECKED=${RUN_NAME_LIST}_checked

ssh $SSH_USER@$HOST "cd $PATH_TARGET_DIR; md5sum -c $RUN_NAME_LIST > $PATH_TARGET_DIR/$RUN_NAME_CHECKED"
md5_check_val=`ssh $SSH_USER@$HOST "grep -w FAILED $PATH_TARGET_DIR/$RUN_NAME_CHECKED|cut -f1"`

if [ "$md5_check_val" -eq 0 ]; then
  msg="MD5 check for the file transfer of sequencing run $RUN_NAME failed. Processing aborted."
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi

msg="file md5 check post transfer has finished for run $RUN_NAME"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

# Mark sequencing run as known
echo $RUN_NAME >> $TRANSFER_DIR/../seqrun/RUN_LIST

# Change to original working dir
cd $WORKING_DIR		
 
# Execute the bcl to cram script
msg="running hpc jobs for $RUN_NAME"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

ssh $SSH_USER@$HOST "source /etc/bashrc; $PATH_BCL2CRAM_SCRIPT -i $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME -t $USE_IRODS -a $REMOVE_ADAPTORS -b $REMOVE_BAMS -p $BASE_PYTHON_DIR -s $SLACK_TOKEN"

retval=$?
if [ "$retval" -ne 0 ]; then
  msg="got error while running hpc job"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
fi


