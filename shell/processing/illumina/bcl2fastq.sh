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

# Stage required files
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


# Undetermined indices fastqs
############################

mkdir -m 770 -p $PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices/Sample_lane${ILANE}

for FAILED_FASTQ in `find $TMPDIR/$RUN_NAME/${ILANE}/fastq/ -mindepth 1 -maxdepth 1 -type f -name 'Undetermined_*.fastq.gz' -exec basename {} \;`
do
   cp $TMPDIR/$RUN_NAME/${ILANE}/fastq/$FAILED_FASTQ $PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices/Sample_lane${ILANE}/
done


# Sample fastqs
##############

# Iterate over project folders
for PROJECT_DIR in `find $TMPDIR/$RUN_NAME/${ILANE}/fastq -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
do	
        if [ $PROJECT_DIR != 'Stats' ] && [ $PROJECT_DIR != 'Reports' ]; then
	  mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}
	  chmod 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}
          cp $PATH_SAMPLE_SHEET $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/SampleSheet.csv
          chmod 660 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/SampleSheet.csv

	  for SAMPLE_DIR_NAME in `find $TMPDIR/$RUN_NAME/${ILANE}/fastq/$PROJECT_DIR/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
	  do
		#...parse sample name
		SAMPLE_ID=$SAMPLE_DIR_NAME
		echo "`$NOW`$SAMPLE_ID"

                # hack for getting sample name
                sample_name_col=0
                sample_id_col=0
                rowcount=0

                for sampleSheetRow in `awk 'BEGIN{data_block=0}{if($0 ~ /^\[Data\]/){data_block=1; next}if(data_block==1){print $0}}' $PATH_SAMPLE_SHEET`
                do
                    rowcount=$(( $rowcount + 1 ))
                    if [ "$rowcount" -eq "1" ]; then
                      sample_name_col=`echo $sampleSheetRow | awk -F',' -v tag='Sample_Name' '{ for(i=1;i<=NF;i++){if($i ~ tag){print i}}}'`
                      sample_id_col=`echo $sampleSheetRow | awk -F',' -v tag='Sample_ID' '{ for(i=1;i<=NF;i++){if($i ~ tag){print i}}}'`
                      continue
                    fi
                    if [ $sample_name_col -gt 0 ] && [ $sample_id_col -gt 0 ]; then
                      sample_name_val=`echo $sampleSheetRow |cut -d',' -f${sample_name_col}`
                      sample_id_val=`echo $sampleSheetRow |cut -d',' -f${sample_id_col}`

                      if [ $sample_id_val == $SAMPLE_ID ]; then
                        SAMPLE_NAME=$sample_name_val
                      fi
                    else
                      echo 'sample id and name column not found'
                      exit 1
                    fi
                done

                if [ ! $SAMPLE_NAME ]; then
                  echo 'sample name not found'
                  exit 1
                fi

                echo "`$NOW`$SAMPLE_NAME"


		SAMPLE_DIR_PATH=$TMPDIR/$RUN_NAME/${ILANE}/fastq/$PROJECT_DIR/$SAMPLE_DIR_NAME
		mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/$SAMPLE_NAME
		chmod -R 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq

                mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/Reports
                mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/Stats
 
                # copying Stats and Reports to each project dir
                cp -r $TMPDIR/$RUN_NAME/${ILANE}/fastq/Reports $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/
                cp -r $TMPDIR/$RUN_NAME/${ILANE}/fastq/Stats $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/
                 
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

