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
INPUT_SEQRUN=$1
RUN_NAME=`basename $INPUT_SEQRUN`
PATH_SEQRUNS_DIR=`dirname $INPUT_SEQRUN`
IRODS_USER=mmuelle1
IRODS_PWD=mmuelle1
PATH_SEQRUNS_DIR_IRODS=/igfZone/home/IRODS_USER
RESOURCE=orwellResc


TRANSFER_DIR=/home/igf/transfer
DATA_HANDLING_LOG_IRODS=/home/igf/log/irods_rundata_handler.${RUN_NAME}.log

HOST=login.cx1.hpc.ic.ac.uk
DATA_VOL_IGF=/project/tgu
bcl2cram_script_path=/home/mmuelle1/git/data-management/shell/processing/illumina/qbcl2cram

#initialise log file
echo -n "" > $DATA_HANDLING_LOG_IRODS

#generating tar archive of the files required for BCL-to-fastq conversion:
# * Data directory
# * runParameters.xml
# * RunInfo.xml
# * <FLOWCELL_ID>.csv

#extract flow cell ID from run name
FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`

echo "`$NOW` Creating sequencing run $RUN_NAME..."
WORKING_DIR=$PWD
echo "`$NOW` Creating TAR archive..." >> $DATA_HANDLING_LOG_IRODS
cd $PATH_SEQRUNS_DIR/$RUN_NAME
tar cvf $TRANSFER_DIR/$RUN_NAME.tar Data runParameters.xml RunInfo.xml $FLOWCELL_ID.csv >> $DATA_HANDLING_LOG_IRODS

#generate an md5 checksum for the tarball
#need to change to location of archive to generate md5
echo "`$NOW` Generating md5 checksum for TAR archive..."
cd $TRANSFER_DIR
md5sum $RUN_NAME.tar > $RUN_NAME.tar.md5

#log into irods using iinit [password]
iinit $IRODS_PWD

echo "`$NOW` Registering files into iRODS..." >> $DATA_HANDLING_LOG_IRODS
#give rx permissions to irods to enable registering..
chmod o+rx $TRANSFER_DIR/$RUN_NAME.tar $TRANSFER_DIR/$RUN_NAME.tar.md5

#register archive and md5 file
ireg -f -R $RESOURCE $TRANSFER_DIR/$RUN_NAME.tar $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME.tar
ireg -f -R $RESOURCE $TRANSFER_DIR/$RUN_NAME.tar.md5 $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME.tar.md5

#change to original working dir
cd $WORKING_DIR		


#transfer files to cx1

#create the run-specific directory where its archive will be retrieved to
PATH_TARGET_DIR=$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME
echo "`$NOW` Creating target directory on $HOST..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "mkdir -m 770 -p " $PATH_TARGET_DIR

#after registration, on cx1, retrieve the files into their respective directories
echo "`$NOW` Retrieving archive to from iRODS..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "source /etc/bashrc; module load irods; iinit $IRODS_PWD; iget -f $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME.tar $PATH_SEQRUNS_DIR_IRODS/$RUN_NAME.tar.md5 $PATH_TARGET_DIR"

#check the md5 checksum of the tarball
echo "`$NOW` Verifying md5 checksum..." >> $DATA_HANDLING_LOG_IRODS
##change to location where the tar and the md5 file are
ssh $HOST "cd $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME; md5sum -c $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar.md5" >> $DATA_HANDLING_LOG_IRODS

#untar the files required for bcl to cram conversion
echo "`$NOW` Extracting archive..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "tar xvf $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar -C $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME" >> $DATA_HANDLING_LOG_IRODS

#after getting the necessary files, we can now delete the .tar and .md5 of that run
echo "`$NOW` Deleting archive and md5 file..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "rm $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar*"

#also, delete the .tar and .md5 of that run from irods, as they are no longer necessary
echo "`$NOW` Removing archive and md5 file from iRODS..." >> $DATA_HANDLING_LOG_IROD
irm -f /igfZone/home/$IRODS_USER/$RUN_NAME.tar
irm -f /igfZone/home/$IRODS_USER/$RUN_NAME.tar.md5

#execute the bcl to cram script
echo "`$NOW` Starting BCL-to-CRAM conversion..." >> $DATA_HANDLING_LOG_IROD
ssh $HOST "source /etc/bashrc; $bcl2cram_script_path -i $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME -d" >> $DATA_HANDLING_LOG_IRODS


 



