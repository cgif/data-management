#!/bin/bash

#
# script to runbclToFastq 
#

#PBS -l walltime=#walltimeHours:00:00
#PBS -l select=1:ncpus=#threads:mem=#required_memory:tmpspace=#tmpSpacegb

#PBS -m ea
#PBS -M igf@imperial.ac.uk
#PBS -j oe

#PBS -q #queue

module load bcl2fastq/#bcl2FastqVersion

#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
BASE_PYTHON_DIR=#base_python_dir

#set python path
export PYTHONPATH=$BASE_PYTHON_DIR

#number of threads for BCL conversion
LOADING_THREADS=#loading_threads
PROCESSING_THREADS=#processing_threads
WRITING_THREADS=#writing_threads

PATH_SEQRUN_DIR=#pathSeqRunDir
PATH_RAWDATA_DIR=#pathRawDataDir
PATH_SAMPLE_SHEET=#pathSampleSheet
RUN_NAME=#runName

RUN_DATE=`echo $RUN_NAME | perl -e 'while(<>){ if(/^(\d{2})(\d{2})(\d{2})_/){ print "20$1-$2-$3"; }}'`;

#extract flowcell ID from run name:
#HiSeq run: the flowcell ID is the last token of the run name preceeded by A or B
# depending on wether the flow cell was run as flowcell A or B on the machine: <[A|B]><flowcell_id>
#MiSeq run: MiSeq runs are detected by the hyphen in the last token of the run name;
#for MiSeq runs the flowcell ID is the token after the hyphen: 000000000-<flowcell_id>

FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$id=<>; chomp($id); if( $id !~ /-/){ $id=~s/^[AB]//; } print $id'`

BASES_MASK=#basesMask
LANE=#lane
ILANE=#ilane

mkdir -p $TMPDIR/$RUN_NAME/$ILANE/fastq

#stage required files
#####################
python $BASE_PYTHON_DIR/scripts/file_copy/moveFilesForDemultiplexing.py -i $PATH_SEQRUN_DIR -o $TMPDIR/$RUN_NAME/$ILANE -s $PATH_SAMPLE_SHEET -r $PATH_SEQRUN_DIR/RunInfo.xml

# Run BC2Fastq
###################

bcl2fastq \
--runfolder-dir $TMPDIR/$RUN_NAME/$ILANE \
--sample-sheet  $PATH_SAMPLE_SHEET \
--output-dir $TMPDIR/$RUN_NAME/$ILANE/fastq \
-r $LOADING_THREADS \
-p $PROCESSING_THREADS \
-w $WRITING_THREADS \
--use-bases-mask $BASES_MASK \
--barcode-mismatches 1 \
--auto-set-to-zero-barcode-mismatches


#undetermined indices fastqs
############################

## Not copying Undetermined fastq files to any projects


#sample fastqs
##############

#iterate over project folders
for PROJECT_DIR in `find $TMPDIR/$RUN_NAME/${ILANE}/fastq -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
do	
        if [ $PROJECT_DIR != 'Stats' ] && [ $PROJECT_DIR != 'Reports' ]; then
	  mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}
	  chmod 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}
          cp $PATH_SAMPLESHEET $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/SampleSheet.csv
          chmod 660 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/SampleSheet.csv

	  for SAMPLE_DIR_NAME in `find $TMPDIR/$RUN_NAME/${ILANE}/fastq/$PROJECT_DIR/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
	  do
		#...parse sample name
		SAMPLE_NAME=$SAMPLE_DIR_NAME
		echo "`$NOW`$SAMPLE_NAME"

		SAMPLE_DIR_PATH=$TMPDIR/$RUN_NAME/${ILANE}/fastq/$PROJECT_DIR/$SAMPLE_DIR_NAME
		mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/$SAMPLE_NAME
		chmod 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}
		chmod 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE
		chmod 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq

                mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/Reports
                mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/Stats
 
                # copying Stats and Reports to each project dir
                cp -r $TMPDIR/$RUN_NAME/${ILANE}/fastq/Reports $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/Reports
                cp -r $TMPDIR/$RUN_NAME/${ILANE}/fastq/Stats $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/Stats
                 
                #set destination directory path
		DESTINATION_DIR=$PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/$SAMPLE_NAME

		#store current working directory
		WORKING_DIR=$PWD
			
		#change to sample directory
		cd $SAMPLE_DIR_PATH
			
		#this file contains the sample under the threshold of reads
		for FASTQ_FILE in `ls --color=never *.fastq*.gz`
		do
			#...make fastq output file name
			FASTQ_FILE=`basename $FASTQ_FILE`
                        FASTQ_NAME=`echo $FASTQ_FILE | perl -pe "s/^${SAMPLE_NAME}_/${RUN_NAME}_/"`
                      
                        mv $FASTQ_FILE $FASTQ_NAME
			md5sum $FASTQ_NAME > $FASTQ_NAME.md5
			
			#fastq
			cp -av $FASTQ_NAME $DESTINATION_DIR/ 				
			chmod 660 $DESTINATION_DIR/$FASTQ_NAME

			#md5
			cp -v $FASTQ_NAME.md5 $DESTINATION_DIR/ 				
			chmod 660 $DESTINATION_DIR/$FASTQ_NAME.md5

		done
		cd $WORKING_DIR
	  done
      fi
done


## adding html for lanes statistics
######################################

# Not adding any HTML

