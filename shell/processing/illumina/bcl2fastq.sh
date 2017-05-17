#!/bin/bash

#
# script to runbclToFastq 
#

#PBS -l walltime=#walltimeHours:00:00
#PBS -l select=1:ncpus=#threads:mem=#required_memory:tmpspace=#tmpSpacegb

#PBS -m ea
#PBS -M igf@imperial.ac.uk
#PBS -j oe

#PBS -q pqcgi

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

SLACK_URL=https://slack.com/api/chat.postMessage
SLACK_OPT="-d 'channel'='C4W5G8550' -d 'username'='igf_bot'"
SLACK_TOKEN=#slackToken

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

msg="started bcl2fastq conversion for $RUN_NAME/$ILANE"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

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


msg="finished bcl2fastq conversion for $RUN_NAME/$ILANE"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

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
        msg="moving fastq files to $PROJECT_DIR"
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

        if [ $PROJECT_DIR != 'Stats' ] && [ $PROJECT_DIR != 'Reports' ]; then
	  mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}
	  chmod 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}

          # filter samplesheet and only keep lines for matching project
          awk -v tag=$PROJECT_DIR -v filter="Sample_ID" 'BEGIN{line_count=0}{if(line_count == 0){print};if($0 ~ filter){line_count=1}else{if( $0 ~ tag){print}}}' $PATH_SAMPLE_SHEET > $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/SampleSheet.csv

          chmod 660 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/SampleSheet.csv

          msg="copying Stats and Reports to $PROJECT_DIR $ILANE"
          res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

          cp -r $TMPDIR/$RUN_NAME/${ILANE}/fastq/Reports $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/
          cp -r $TMPDIR/$RUN_NAME/${ILANE}/fastq/Stats $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/

          # Store current working directory
          WORKING_DIR=$PWD

	  for SAMPLE_DIR_NAME in `find $TMPDIR/$RUN_NAME/${ILANE}/fastq/$PROJECT_DIR/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
	  do
            # SAMPLE
            msg="creating dir structure for $PROJECT_DIR $ILANE $SAMPLE_DIR_NAME"
            res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
 
            # Set source dir
            SAMPLE_DIR_PATH=$TMPDIR/$RUN_NAME/${ILANE}/fastq/$PROJECT_DIR/$SAMPLE_DIR_NAME
 
            # Set destination directory path
            DESTINATION_DIR=$PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/$SAMPLE_DIR_NAME

            mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq/$RUN_DATE/${ILANE}/$SAMPLE_DIR_NAME
            chmod -R 770 $PATH_RAWDATA_DIR/$PROJECT_DIR/fastq
		
	    # Change to sample directory
	    cd $SAMPLE_DIR_PATH
                  
            msg="copying fastq files for $PROJECT_DIR $ILANE $sample_id_val"
            res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

            for FASTQ_FILE in `find . -type f -name '*.fastq*.gz' -exec basename {} \;`
            do
              # FASTQ FILE
              FASTQ_NAME="${RUN_NAME}_${FASTQ_FILE}"
             
              mv $FASTQ_FILE $FASTQ_NAME

              md5sum $FASTQ_NAME > $FASTQ_NAME.md5

              # Copy fastq
              cp $FASTQ_NAME $DESTINATION_DIR/ 
              chmod 550 $DESTINATION_DIR/$FASTQ_NAME
  
              # Copy md5
              cp $FASTQ_NAME.md5 $DESTINATION_DIR/ 
              chmod 550 $DESTINATION_DIR/$FASTQ_NAME.md5 
            done			
            # SAMPLE
            cd $WORKING_DIR
          done  
        fi
done

msg="finished fastq move for $RUN_NAME/$ILANE"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`


