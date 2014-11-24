#!/bin/bash




NOW="date +%m/%d/%Y_%H:%M:%S"

RUN_DIR=$1
RUN_NAME=`basename $RUN_DIR`
SEQ_RUNS_DIR=`dirname $RUN_DIR`

TRANSFER_DIR=/home/igf/transfer
DATA_VOL_IGF=/project/tgu
HOST=login.cx1.hpc.ic.ac.uk
bcl2cram_script_path=/home/mkanwagi/git/data-management/shell/processing/illumina/qbcl2cram
runs_info_file=/home/igf/seqrun/run_db.txt


DATA_HANDLING_LOG=/home/igf/log/rundata_handling.$RUN_NAME.log




echo "`$NOW` Initiating data handling log file for run $RUN_NAME ..."
echo -n "" > $DATA_HANDLING_LOG

#TODO redirect error output to stdout


FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`


#for completed runs, tar together those files required for bcl 2 cram conversion

working_dir=$PWD

echo "`$NOW` archiving files for the sequencing run $RUN_NAME ..." >> $DATA_HANDLING_LOG
cd $SEQ_RUNS_DIR/$RUN_NAME
tar cvf $TRANSFER_DIR/$RUN_NAME.tar Data runParameters.xml RunInfo.xml $FLOWCELL_ID.csv >> $DATA_HANDLING_LOG


#generate an md5 checksum for the tarball
cd $TRANSFER_DIR
md5sum $RUN_NAME.tar > $RUN_NAME.tar.md5
cd $working_dir

#create the run-specific directory where its archive will be copied to
echo "`$NOW` creating target directoyr on $HOST ..." >> $DATA_HANDLING_LOG
ssh login.cx1.hpc.ic.ac.uk "mkdir -m 770 -p $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME"

#copy the tarball to cx1, along with its md5 file
echo "`$NOW` copying archive for the sequencing run $RUN_NAME to $HOST..." >> $DATA_HANDLING_LOG

#write transfer_start_time to the runs_info file
transfer_start=`$NOW`

echo "awk"
/home/mkanwagi/testperl.pl $RUN_NAME transfer_start_time $transfer_start $runs_info_file > $runs_info_file.new && mv $runs_info_file.new $runs_info_file


echo "scp"
scp $TRANSFER_DIR/$RUN_NAME.tar  $TRANSFER_DIR/$RUN_NAME.tar.md5  login.cx1.hpc.ic.ac.uk:$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/
echo "`$NOW`done" >> $DATA_HANDLING_LOG

#write transfer_end_time to the runs_info file
transfer_end=`$NOW`
/home/mkanwagi/testperl.pl $RUN_NAME transfer_end_time $transfer_end $runs_info_file > $runs_info_file.new && mv $runs_info_file.new $runs_info_file






# MEANWHILE ON CX1...

#check the md5 checksum of the tarball
echo "`$NOW` checking the md5 checksum for the sequencing run $RUN_NAME ..." >> $DATA_HANDLING_LOG
##change to location where the tar and the md5 file are
ssh login.cx1.hpc.ic.ac.uk "cd $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME; md5sum -c $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar.md5" >> $DATA_HANDLING_LOG


#untar the files required for bcl to cram conversion
echo "`$NOW` untarring the archive of $RUN_NAME ..." >> $DATA_HANDLING_LOG
ssh login.cx1.hpc.ic.ac.uk "tar xvf $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar -C $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME" >> $DATA_HANDLING_LOG

ssh login.cx1.hpc.ic.ac.uk "rm $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$RUN_NAME.tar* "

#write conversion_start_time to the runs_info file
conversion_start=`$NOW`

/home/mkanwagi/testperl.pl $RUN_NAME conversion_start_time $conversion_start $runs_info_file > $runs_info_file.new && mv $runs_info_file.new $runs_info_file


#execute the bcl to cram script
#ssh login.cx1.hpc.ic.ac.uk "$bcl2cram_script_path -i $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME" >> $DATA_HANDLING_LOG



#write conversion_end_time to runs_info file is done by bam2cram script; at the end of it
#the following lines will be included there;
#	conversion_end=`$NOW`
#	runs_info_file=/home/igf/seqrun/illumina/run_db.txt		#the location of the runs_info file has to be defined like this in that script 
#	ssh eliot.med.ic.ac.uk "/home/mkanwagi/testperl.pl $RUN_NAME conversion_end_time $conversion_end $runs_info_file > $runs_info_file.new && mv $runs_info_file.new $runs_info_file"


echo -e "\n `$NOW` All done! :) \n"

