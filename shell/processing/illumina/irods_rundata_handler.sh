#!/bin/bash


#This script runs on orwell
#It handles data of a single sequencing run
#The script does the following things; creates an archive of only the files necessary for fastq file generation
#					generates an md5 checksum for that archive
#					the archive and md5 file are registered into irods; to register any file that file has to have 'rx' permissions for 'everyone-else'
#					After registration into irods,
#					On CX1, the archive is extracted into a RUN-specific folder on /project/tgu/rawdata/seqrun
#					Then the data is sent to the qbcl2cram script





NOW="date +%m/%d/%Y_%H:%M:%S"
INPUT_SEQRUN=$1
RUN_NAME=`basename $INPUT_SEQRUN`
ORWELL_SEQRUNS_DIR=`dirname $INPUT_SEQRUN`
IRODS_SEQRUNS_DIR=/igfZone/home/mmuelle1
RESOURCE=orwellResc

TRANSFER_DIR=/home/igf/transfer/irods_tars
DATA_HANDLING_LOG_IRODS=/home/igf/log/irods_rundata_handling.${RUN_NAME}.log

HOST=login.cx1.hpc.ic.ac.uk
DATA_VOL_IGF=/project/tgu
bcl2cram_script_path=/home/mkanwagi/git/data-management/shell/processing/illumina/qbcl2cram


echo "`$NOW` Initializing irods data handling log for $RUN_NAME ..."
echo -n "" > $DATA_HANDLING_LOG_IRODS

####generating the tar archive the required seqrun files
FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`

working_dir=$PWD
echo "`$NOW` archiving files for the sequencing run $RUN_NAME ..." >> $DATA_HANDLING_LOG_IRODS
cd $ORWELL_SEQRUNS_DIR/$RUN_NAME
tar cvf $TRANSFER_DIR/$RUN_NAME.tar Data runParameters.xml RunInfo.xml $FLOWCELL_ID.csv >> $DATA_HANDLING_LOG_IRODS


#generate an md5 checksum for the tarball; need to change to location of archive to generate md5
cd $TRANSFER_DIR
md5sum $RUN_NAME.tar > $RUN_NAME.tar.md5


#log into irods; using iinit [password]
iinit mmuelle1

echo "`$NOW` registering archive of $RUN_NAME into iRODS..." >> $DATA_HANDLING_LOG_IRODS
#give rx permissions to irods to enable registering..
chmod o+rx $TRANSFER_DIR/$RUN_NAME.tar $TRANSFER_DIR/$RUN_NAME.tar.md5

#register archive and md5 file
ireg -f -R $RESOURCE $TRANSFER_DIR/$RUN_NAME.tar $IRODS_SEQRUNS_DIR/$RUN_NAME.tar
ireg -f -R $RESOURCE $TRANSFER_DIR/$RUN_NAME.tar.md5 $IRODS_SEQRUNS_DIR/$RUN_NAME.tar.md5

cd $working_dir		#change directory, out of .tar file directory, to the original working dir




#....MEANWHILE ON CX1

#create the run-specific directory where its archive will be retrieved to
echo "`$NOW` creating target directory on $HOST ..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "mkdir -m 770 -p $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME"


#after registration, on cx1, retrieve the files into their respective directories
echo "`$NOW` retrieving archive of $RUN_NAME from iRODS..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "source /etc/bashrc; module load irods; iinit mmuelle1; iget -f $IRODS_SEQRUNS_DIR/$RUN_NAME.tar $IRODS_SEQRUNS_DIR/$RUN_NAME.tar.md5 $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/"



#check the md5 checksum of the tarball
echo "`$NOW` verifying the md5 checksum for the sequencing run $RUN_NAME ..." >> $DATA_HANDLING_LOG_IRODS
##change to location where the tar and the md5 file are
ssh $HOST "cd $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME; md5sum -c $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar.md5" >> $DATA_HANDLING_LOG_IRODS


#untar the files required for bcl to cram conversion
echo "`$NOW` extracting the archive of $RUN_NAME ..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "tar xvf $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar -C $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME" >> $DATA_HANDLING_LOG_IRODS

#after getting the necessary files, we can now delete the .tar and .md5 of that run
echo "`$NOW` deleting the archive and md5 file of $RUN_NAME ..." >> $DATA_HANDLING_LOG_IRODS
ssh $HOST "rm $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar*"


#also, delete the .tar and .md5 of that run from irods, as they are no longer necessary
irm -f /igfZone/home/mmuelle1/$RUN_NAME.tar
irm -f /igfZone/home/mmuelle1/$RUN_NAME.tar.md5


#execute the bcl to cram script

ssh $HOST "source /etc/bashrc; $bcl2cram_script_path -i $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME -r T " >> $DATA_HANDLING_LOG_IRODS


 



