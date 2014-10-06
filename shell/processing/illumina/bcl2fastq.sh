#!/bin/bash

#
# script to runbclToFastq 
#
#24/9 changed this line from -l select=1:ncpus=2:mem=7800mb:tmpspace=1000gb to its current state

#PBS -l walltime=#walltimeHours:00:00
#PBS -l select=1:ncpus=#threads:mem=1024mb:tmpspace=#tmpSpacegb


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
DATA_VOL_IGF=#dataVolIgf

#number of threads for BCL conversion
THREADS=#threads

PATH_SEQRUN_DIR=#pathSeqRunDir
RUN_NAME=#runName
FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`
LANE=#lane

echo "`$NOW`: staging input files..."
#create temporary run folder
mkdir -p $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Matrix

mkdir -p $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Phasing


#stage required files
#####################

#samplesheet
echo "`$NOW`$PATH_SEQRUN_DIR/$FLOWCELL_ID.csv"


head -n1 $PATH_SEQRUN_DIR/$FLOWCELL_ID.csv > $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv
cat $PATH_SEQRUN_DIR/$FLOWCELL_ID.csv | awk -F',' "{ if (\$2 == $LANE) { print;} }" >> $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

cat $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

#run info
echo "`$NOW`$PATH_SEQRUN_DIR/RunInfo.xml"
cp $PATH_SEQRUN_DIR/RunInfo.xml $TMPDIR/$RUN_NAME
#run parameters
echo "`$NOW`$PATH_SEQRUN_DIR/runParameters.xml"
cp $PATH_SEQRUN_DIR/runParameters.xml $TMPDIR/$RUN_NAME

#intensities config
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/config.xml"
cp $PATH_SEQRUN_DIR/Data/Intensities/config.xml $TMPDIR/$RUN_NAME/Data/Intensities
#RTA config
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/RTAConfiguration.xml"
cp $PATH_SEQRUN_DIR/Data/Intensities/RTAConfiguration.xml $TMPDIR/$RUN_NAME/Data/Intensities

#basecalls config
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/config.xml"
cp $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/config.xml $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls

#data

#offsets
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/Offsets"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/Offsets $TMPDIR/$RUN_NAME/Data/Intensities

#intensities
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/L00${LANE}"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/L00${LANE} $TMPDIR/$RUN_NAME/Data/Intensities

#basecalls
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/L00${LANE}"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/L00${LANE} $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls

#Matrix
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Matrix/s_${LANE}_*"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Matrix/s_${LANE}_* $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Matrix

#Phasing
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Phasing/s_${LANE}_*"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Phasing/s_${LANE}_* $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Phasing



#create a makefile for Bcl conversion
#######################################

echo "`$NOW`: creating make file for Bcl->fastq conversion..."
$CASAVA_HOME/bin/configureBclToFastq.pl --fastq-cluster-count -1 --input-dir $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls --sample-sheet $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

echo "`$NOW`: running Bcl->fastq conversion conversion..."
cd $TMPDIR/$RUN_NAME/Unaligned		#changing to the 'Unaligned' sub-folder of the project to configure
make -j $THREADS


echo "`$NOW`copying sample fastq files to $DATA_VOL_IGF/rawdata..."

for PROJECT_DIR in `ls --color=never $TMPDIR/$RUN_NAME/Unaligned | grep Project_`

do	

	
	#Obtaining the project names so that we are able to store the generated fastQ files directly into their corresponding project directories
	PROJECT_NAME=`echo $PROJECT_DIR | cut -f2 -d '_'`
	mkdir -p $DATA_VOL_IGF/rawdata/AZ/$PROJECT_NAME/fastq

	for SAMPLE_DIR in `ls --color=never $TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/`
	do
		
		SAMPLE_NAME=`echo $SAMPLE_DIR | cut -f2 -d '_'`
		mkdir -p $DATA_VOL_IGF/rawdata/AZ/$PROJECT_NAME/fastq/$SAMPLE_NAME

		for FASTQ_FILE in `ls --color=never $TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_DIR`
		do

			echo "`$NOW`$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_DIR/$FASTQ_FILE"
			FASTQ_NAME=`echo $FASTQ_FILE | perl -pe "s/^${SAMPLE_NAME}_/${RUN_NAME}_/"`
			cp $TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_DIR/$FASTQ_FILE $DATA_VOL_IGF/rawdata/AZ/$PROJECT_NAME/fastq/$SAMPLE_NAME/$FASTQ_NAME

		done

	done
	
done

echo "`$NOW`copying undetermined indices fastq files to $DATA_VOL_IGF/rawdata..."

#create output directory
mkdir -p $DATA_VOL_IGF/rawdata/seqrun/fastq/$RUN_NAME/

#copy files
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/Undetermined_indices $DATA_VOL_IGF/rawdata/seqrun/fastq/$RUN_NAME/

ls -al $TMPDIR/*
ls -al $TMPDIR/$RUN_NAME/Unaligned/*

du -sh $TMPDIR

