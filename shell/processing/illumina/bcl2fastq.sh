#!/bin/bash

#
# script to runbclToFastq 
#
#24/9 changed this line from -l select=1:ncpus=16:mem=7800mb:tmpspace=1000gb to its current state

#PBS -l walltime=72:00:00
#PBS -l select=1:ncpus=16:mem=48000mb:tmpspace=500gb


#PBS -m ea
#PBS -M mkanwagi@imperial.ac.uk
#PBS -j oe

#PBS -q pqcgi


module load casava/1.8.2


#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
SCRIPT_NAME=$0
#GROUP_VOL_CGI=/groupvol/cgi
DATA_VOL_IGF=/project/tgu

#number of threads for BCL conversion
THREADS=16
RUN_NAME=140530_SN674_0277_BC3YBMACXX
FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`
LANE=1

LOG=/home/mkanwagi/scripts/casava_test_run.log
cat -n "" > $LOG 

echo "`$NOW`: staging input files..." >> $LOG 
#create temporary run folder
mkdir -p $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Matrix

mkdir -p $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Phasing


#stage required files
#####################

#samplesheet
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$FLOWCELL_ID.csv" >> $LOG 


head -n1 $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$FLOWCELL_ID.csv > $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv
cat $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$FLOWCELL_ID.csv | awk -F',' "{ if (\$2 == $LANE) { print;} }" >> $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

cat $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv  >> $LOG

#run info
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/RunInfo.xml" >> $LOG
cp $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/RunInfo.xml $TMPDIR/$RUN_NAME
#run parameters
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/runParameters.xml" >> $LOG
cp $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/runParameters.xml $TMPDIR/$RUN_NAME

#intensities config
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/config.xml" >> $LOG
cp $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/config.xml $TMPDIR/$RUN_NAME/Data/Intensities
#RTA config
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/RTAConfiguration.xml" >> $LOG
cp $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/RTAConfiguration.xml $TMPDIR/$RUN_NAME/Data/Intensities

#basecalls config
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/config.xml" >> $LOG
cp $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/config.xml $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls

#data

#offsets
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/Offsets" >> $LOG
cp -r $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/Offsets $TMPDIR/$RUN_NAME/Data/Intensities

#intensities
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/L00${LANE}" >> $LOG
cp -r $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/L00${LANE} $TMPDIR/$RUN_NAME/Data/Intensities

#basecalls
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/L00${LANE}" >> $LOG
cp -r $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/L00${LANE} $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls

#Matrix
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/Matrix/s_${LANE}_*" >> $LOG
cp -r $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/Matrix/s_${LANE}_* $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Matrix

#Phasing
echo "`$NOW`$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/Phasing/s_${LANE}_*" >> $LOG
cp -r $DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/Data/Intensities/BaseCalls/Phasing/s_${LANE}_* $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Phasing



#create a makefile for Bcl conversion
#######################################

echo "`$NOW`: creating make file for Bcl->fastq conversion..." >> $LOG
$CASAVA_HOME/bin/configureBclToFastq.pl --input-dir $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls --sample-sheet $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

echo "`$NOW`: running Bcl->fastq conversion conversion..." >> $LOG
cd $TMPDIR/$RUN_NAME/Unaligned		#changing to the 'Unaligned' sub-folder of the project to configure
make -j $THREADS


echo "`$NOW`: copying results to $DATA_VOL_IGF/rawdata/seqrun/fastq/$RUN_NAME..." >> $LOG
#create output directory
mkdir -p $DATA_VOL_IGF/rawdata/seqrun/fastq/$RUN_NAME/

#copy files
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/* $DATA_VOL_IGF/rawdata/seqrun/fastq/$RUN_NAME/

ls -al $TMPDIR/*
ls -al $TMPDIR/$RUN_NAME/Unaligned/*

du -sh $TMPDIR

