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

RUN_NAME=`basename $INPUT_SEQRUN`
PATH_SEQRUNS_DIR=`dirname $INPUT_SEQRUN`

PATH_SEQRUNS_DIR_IRODS=/igfZone/home/$IRODS_USER/seqrun/illumina
RESOURCE=orwellResc


TRANSFER_DIR=/home/igf/transfer
LOG=/home/igf/log/seqrun_processing/$RUN_NAME.log

HOST=login.cx1.hpc.ic.ac.uk
DATA_VOL_IGF=/project/tgu
#PATH_BCL2CRAM_SCRIPT=/home/mmuelle1/git/data-management/shell/processing/illumina/qbcl2cram
PATH_BCL2CRAM_SCRIPT=/home/mcosso/git/data-management/shell/processing/illumina/qbcl2cram

DEPLOYMENT_HOST=eliot.med.ic.ac.uk
DEPLOYMENT_PATH=/www/html/report/project
CUSTOMERS_FILEPATH=/home/igf/docs/igf/users
CUSTOMERS_RUNS_FILE=customerInfo.csv

#initialise log file
echo -n "" >> $LOG


#redirect stdout and stderr to log file
exec > $LOG
exec 2>&1

#generating tar archive of the files required for BCL-to-fastq conversion:
# * Data directory
# * runParameters.xml
# * RunInfo.xml
# * SampleSheet.csv
# * customerInfo.csv

echo "`$NOW` Processing sequencing run $RUN_NAME..."
WORKING_DIR=$PWD

#get SampleSheet filename
#for HiSeq runs the sample sheet is named after the flowcell -> extract flow cell ID from run name
#for MiSeq runs the sample sheet file is names SampleSheet.csv. Miseq run names contain a '-' in the last token.
#SAMPLE_SHEET_PREFIX=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$prefix=<>; chomp($prefix); if($prefix =~ /-/){ $prefix=SampleSheet;  }else{ $prefix=~s/^[AB]//; } print $prefix'`
SAMPLE_SHEET_PREFIX="SampleSheet"


#create TAR archive of files and folders required for BCL2FASTQ conversion (Data folder, runParameters.xml RunInfo.xml and samplesheet)
echo "`$NOW` Creating TAR archive..."
cd $PATH_SEQRUNS_DIR/$RUN_NAME

#check if all required files are present
for FILE in Data runParameters.xml RunInfo.xml $SAMPLE_SHEET_PREFIX.csv
do
	if [[ ! -e $FILE ]]
	then
	
		echo "`$NOW` ERROR: Required file or directory $FILE missing... aborting"
		#send email alert...
		echo -e "subject:Sequencing Run $RUN_NAME Processing Error - Missing file or directory\nRequired file or directory $FILE missing for sequencing run $RUN_NAME. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
		exit 1
			
	fi
done

#creates deployment results structure on eliot webserver
#convert sample sheet & customers info file
dos2unix $SAMPLE_SHEET_PREFIX.csv
dos2unix $CUSTOMERS_FILEPATH/lims_user.csv
#get project information from Sample sheet (project_tag:username)
echo -n "" > $CUSTOMERS_RUNS_FILE
#get the position in the sample_sheet of sample_project column
project_position=`cat $SAMPLE_SHEET_PREFIX.csv| grep Sample_Project | awk -F, '{for(i=1;i<=NF;i++){if($i=="Sample_Project")print i;}}'`

for project_info in `cat $SAMPLE_SHEET_PREFIX.csv |grep -v "Sample_Project"| cut -d ',' -f$project_position| sort | uniq | sed 1d`
do
	#for TEST
	#echo "$project_info PROJECT INFO FILE"
	project_tag=`echo $project_info|cut -d ':' -f1`
	project_usr=`echo $project_info|cut -d ':' -f2`
	#get customer information from customer file Perfect Matching!!
	echo -n $project_tag"," >> $CUSTOMERS_RUNS_FILE
	customers_info=`grep -w $project_usr $CUSTOMERS_FILEPATH/lims_user.csv`
	if [[ -z $customers_info ]]; then
		echo "`$NOW` ERROR: customer for project $project_tag is unknown"
		#send email alert...
		echo -e "subject:Sequencing Run $RUN_NAME Processing Error - customer unknown for project $project_tag. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
		exit 1
	fi
	echo $customers_info >> $CUSTOMERS_RUNS_FILE
done
if [[ ! -e $CUSTOMERS_RUNS_FILE ]]
	then
		echo "`$NOW` ERROR: Required file $CUSTOMERS_RUNS_FILE  missing... aborting"
		#send email alert...
		echo -e "subject:Sequencing Run $RUN_NAME Processing Error - Missing file\nRequired file $CUSTOMERS_RUNS_FILE missing for sequencing run $RUN_NAME. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
		exit 1
	fi

#creates TAR archive
tar cvf $TRANSFER_DIR/$RUN_NAME.tar Data runParameters.xml RunInfo.xml $SAMPLE_SHEET_PREFIX.csv $CUSTOMERS_RUNS_FILE > /dev/null
#for TEST
#tar cvf $TRANSFER_DIR/$RUN_NAME.tar runParameters.xml RunInfo.xml $SAMPLE_SHEET_PREFIX.csv $CUSTOMERS_RUNS_FILE > /dev/null

#generate an md5 checksum for the tarball
#need to change to location of archive to generate md5
#no longer needed as we calculate and check it with iRODS
#echo "`$NOW` Generating md5 checksum for TAR archive..."
cd $TRANSFER_DIR
md5sum $RUN_NAME.tar > $RUN_NAME.tar.md5

#log into irods using iinit [password]
#iinit $IRODS_PWD

echo "`$NOW` Registering files into iRODS..."
#give rx permissions to irods to enable registering..
chmod o+rx $TRANSFER_DIR/$RUN_NAME.tar $TRANSFER_DIR/$RUN_NAME.tar.md5

#register archive and md5 file
#-R the resource to store to
#-k calcualte a checksum on the iRODS client and store with the file details
#--hash md5 - use the specified file checksum
imkdir $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME
ireg -k -R $RESOURCE $TRANSFER_DIR/$RUN_NAME.tar $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar
## checks if there was an error on irods
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR registering run data in IRODS"
    exit 1
fi 
ireg -R $RESOURCE $TRANSFER_DIR/$RUN_NAME.tar.md5 $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar.md5


#change to original working dir
cd $WORKING_DIR		

#transfer files to cx1

#create the run-specific directory where its archive will be retrieved to
PATH_TARGET_DIR=$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME
echo "`$NOW` Creating target directory $PATH_TARGET_DIR on $HOST..."
ssh $SSH_USER@$HOST "mkdir -m 770 -p " $PATH_TARGET_DIR

#after registration, on cx1, retrieve the files into their respective directories
#-K verify the checksum
echo "`$NOW` Retrieving archive from iRODS..."
#ssh $SSH_USER@$HOST "source /etc/bashrc; module load irods/4.2.0; iinit $IRODS_PWD; iget -K $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar.md5 $PATH_TARGET_DIR"
ssh $SSH_USER@$HOST "source /etc/bashrc; module load irods/4.2.0; iget -K $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar.md5 $PATH_TARGET_DIR"

#check the md5 checksum of the tarball
#no longer needed as we calculate and check it with iRODS
echo -n "`$NOW` Verifying md5 checksum..."
#change to location where the tar and the md5 file are
MD5_STATUS=`ssh $SSH_USER@$HOST "cd $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME; md5sum -c $RUN_NAME.tar.md5 2>&1 | head -n 1 | cut -f 2 -d ' '"`
echo  $MD5_STATUS

#abort if md5 check fails
if [[ $MD5_STATUS == 'FAILED' ]]
then

	#send email alert...
	echo -e "subject:Sequencing Run $RUN_NAME Processing Error - MD5 check failed\nThe MD5 check for the file transfer of sequencing run $RUN_NAME failed. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
	
	#...and exit
	exit 1

fi

#untar the files required for bcl to cram conversion
echo "`$NOW` Extracting archive..."
ssh $SSH_USER@$HOST "tar xf $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar -C $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME"


#after getting the necessary files, we can now delete the .tar and .md5 of that run
echo "`$NOW` Deleting tar archive and md5 file from $HOST..."
ssh $SSH_USER@$HOST "rm $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar*"

#also, delete the .tar and .md5 of that run from irods, as they are no longer necessary
echo "`$NOW` Removing tar archive and md5 file from iRODS..."
irm $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar
irm $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME/$RUN_NAME.tar.md5

#remove local copies of tar and md5
echo "`$NOW` Removing local copies of tar archive and md5 file..."
rm $TRANSFER_DIR/$RUN_NAME.tar*

#execute the bcl to cram script
echo "`$NOW` Starting BCL-to-CRAM conversion..."
ssh $SSH_USER@$HOST "source /etc/bashrc; $PATH_BCL2CRAM_SCRIPT -i $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME -d"


