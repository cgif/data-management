#!/bin/bash

#
# script to runbclToFastq 
#

#PBS -l walltime=#walltimeHours:00:00
#PBS -l select=1:ncpus=#threads:mem=1024mb:tmpspace=#tmpSpacegb

#PBS -m ea
#PBS -M igf@imperial.ac.uk
#PBS -j oe

#PBS -q #queue

module load bcl2fastq/#bcl2FastqVersion
#module load casava/1.8.2

#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`

BASEDIR="$( cd "$( dirname "$0" )" && pwd )"
SCRIPT_NAME=$0
DATA_VOL_IGF=#dataVolIgf

#number of threads for BCL conversion
THREADS=#threads

PATH_SEQRUN_DIR=#pathSeqRunDir
PATH_RUN_DIR=#pathRunDir
#PATH_ANALYSIS_DIR=#pathAnalysisDir
PATH_RESULTS_DIR=#pathResultsDir
PATH_RAWDATA_DIR=#pathRawDataDir
PATH_ADAPTER_DIR=#pathAdapterDir
PATH_SAMPLE_SHEET=#pathSampleSheet
PATH_TEMPLATE_HTM=#pathTemplateHtm
RUN_NAME=#runName
ADAPTER_TYPE=#adapterType
DEPLOYMENT_SERVER=#deploymentServer
DEPLOYMENT_PATH=#deploymentPath
MIXED_INDEXES=#mixedIndexes

RUN_DATE=`echo $RUN_NAME | perl -e 'while(<>){ if(/^(\d{2})(\d{2})(\d{2})_/){ print "20$1-$2-$3"; }}'`;

#extract flowcell ID from run name:
#HiSeq run: the flowcell ID is the last token of the run name preceeded by A or B
# depending on wether the flow cell was run as flowcell A or B on the machine: <[A|B]><flowcell_id>
#MiSeq run: MiSeq runs are detected by the hyphen in the last token of the run name;
#for MiSeq runs the flowcell ID is the token after the hyphen: 000000000-<flowcell_id>
#FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$id=<>; chomp($id); if($id =~ /-/){ @tokens=split(/-/,$id); $id=$tokens[1];  }else{ $id=~s/^[AB]//; } print $id'`
FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$id=<>; chomp($id); if(! $id =~ /-/){ $id=~s/^[AB]//; } print $id'`
#FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`
LANE=#lane
BASES_MASK=#basesMask
LANE=#lane
ILANE=#ilane

#READ=#read

echo "`$NOW`staging input files..."
#create temporary run folder
mkdir -p $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Matrix

mkdir -p $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Phasing


#stage required files
#####################

#samplesheet
echo "`$NOW`$PATH_SEQRUN_DIR/$SAMPLE_SHEET"

#creat temporary sample sheet for lane
#remove columns with reference information to make sample sheet compatible with bcl2fastq
#(will otherwise complain about the wrong number of columns in sample sheet

head -n1 $PATH_SAMPLE_SHEET > $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv
cat $PATH_SAMPLE_SHEET | awk -F',' "{ if (\$2 == $LANE) { print;} }" >> $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv
#cat $PATH_SAMPLE_SHEET | perl -e "while(<>){ if(/,Lane,|$FLOWCELL_ID,$LANE,/){ print; }}" | cut -f1,2,3,4,5,6,7,8,9,10 -d ','
#cat $PATH_SAMPLE_SHEET | perl -e "while(<>){ if(/FCID,Lane,|$FLOWCELL_ID,$LANE,/){ print; }}" | cut -f1,2,3,4,5,6,7,8,9,10 -d ',' > $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv
#cp $PATH_SAMPLE_SHEET $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

#run info
echo "`$NOW`$PATH_SEQRUN_DIR/RunInfo.xml"
cp $PATH_SEQRUN_DIR/RunInfo.xml $TMPDIR/$RUN_NAME
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/RunInfo.xml"
    exit 1
fi
#run parameters
echo "`$NOW`$PATH_SEQRUN_DIR/runParameters.xml"
cp $PATH_SEQRUN_DIR/runParameters.xml $TMPDIR/$RUN_NAME
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/runParameters.xml"
    exit 1
fi

echo " MIXED INDEXES $MIXED_INDEXES"
if [ "$MIXED_INDEXES" -gt "0" ];then
#	cat $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv
	echo "`$NOW` Mixed indexes run $MIXED_INDEXES"
        #delete second Index from RunInfo.xml
        sed -i '/Read Number\=\"3\"/d' $TMPDIR/$RUN_NAME/RunInfo.xml
#	cat $TMPDIR/$RUN_NAME/RunInfo.xml
        # set to 0 IndexRead2 in runParameters.xml
        sed -i "s/\(<IndexRead2>\).*\(<\/IndexRead2>\)/\10\2/" $TMPDIR/$RUN_NAME/runParameters.xml
#	cat $TMPDIR/$RUN_NAME/runParameters.xml
fi

cat $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv

#intensities config
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/config.xml"
cp $PATH_SEQRUN_DIR/Data/Intensities/config.xml $TMPDIR/$RUN_NAME/Data/Intensities
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/config.xml"
    exit 1
fi
#RTA config
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/RTAConfiguration.xml"
cp $PATH_SEQRUN_DIR/Data/Intensities/RTAConfiguration.xml $TMPDIR/$RUN_NAME/Data/Intensities
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/RTAConfiguration.xml"
    exit 1
fi

#basecalls config
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/config.xml"
cp $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/config.xml $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/config.xml"
    exit 1
fi

#data

#offsets
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/Offsets"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/Offsets $TMPDIR/$RUN_NAME/Data/Intensities
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/Offsets"
    exit 1
fi

#intensities
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/L00${LANE}"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/L00${LANE} $TMPDIR/$RUN_NAME/Data/Intensities
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/L00${LANE}"
    exit 1
fi

#basecalls
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/L00${LANE}"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/L00${LANE} $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/L00${LANE}"
    exit 1
fi

#Matrix
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Matrix/s_${LANE}_*"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Matrix/s_${LANE}_* $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Matrix
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Matrix/s_${LANE}_*"
    exit 1
fi

#Phasing
echo "`$NOW`$PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Phasing/s_${LANE}_*"
cp -r $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Phasing/s_${LANE}_* $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls/Phasing
retval=$?
if [ $retval -ne 0 ]; then
    echo "`$NOW` ERROR copying $PATH_SEQRUN_DIR/Data/Intensities/BaseCalls/Phasing/s_${LANE}_*"
    exit 1
fi



#create a makefile for Bcl conversion
#######################################

#--fastq-cluster-count 0  create a single fastq file instead of breaking them into sub-files containing reads from a defined number of reads
#--no-eamss               Disable the masking of the quality values with the Read Segment Quality control metric filter. It is recommended to disable EAMSS 
#                         particularly when bcl conversion output needs to match that from other Illumina fastq-generating processes, such as MiSeq Reporter
#                         or BaseSpace fastq generation. EAMMS is no longer required with current Illumina sequencing technology and is not applied in such
#                         newer applications.
#--mismatches 0           allowed mismatches in index sequence (default = 0)
#--ignore-missing-bcl     Interpret missing *.bcl files as no call (N)
#--adapter-sequence       $BCL2FASTQ_HOME/share/bcl2fastq-1.8.4/adapters/TruSeq_r1.fa
#--adapter-sequence       $BCL2FASTQ_HOME/share/bcl2fastq-1.8.4/adapters/TruSeq_r2.fa
#--use-bases-mask         eg y100n,i6n,i6n,y100n

echo "`$NOW`creating make file for Bcl->fastq conversion..."
#/groupvol/cgi/software/bcl2fastq/1.8.4/configureBclToFastq.pl --fastq-cluster-count 0 --mismatches 0 --no-eamss --input-dir $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls --sample-sheet $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv 

############################################## XXXXXX ######################################
# Now based on Adapter Type call bcl2fastq converter passing the adapter in acconrding

case "$ADAPTER_TYPE" in
	"truseq" )
	adapter_r1=TruSeq_r1.fa
	adapter_r2=TruSeq_r2.fa
	;;
	"smallrna" )
	adapter_r1=SmallRNA_r1.fa
	adapter_r2=SmallRNA_r2.fa
	;;
	"nextera" )
	adapter_r1=Nextera_r1.fa
	adapter_r2=Nextera_r2.fa
	;;
esac

#for TEST
echo "`$NOW` $adapter_r1 $adapter_r2"
	
$BCL2FASTQ_HOME/bin/configureBclToFastq.pl --use-bases-mask $BASES_MASK --fastq-cluster-count 0 --mismatches 0 --no-eamss --adapter-sequence $PATH_ADAPTER_DIR/$adapter_r1 --adapter-sequence $PATH_ADAPTER_DIR/$adapter_r2 --input-dir $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls --sample-sheet $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv 

#$BCL2FASTQ_HOME/bin/configureBclToFastq.pl --use-bases-mask $BASES_MASK --fastq-cluster-count 0 --mismatches 0 --no-eamss --adapter-sequence $BCL2FASTQ_HOME/share/bcl2fastq-1.8.4/adapters/TruSeq_r1.fa --adapter-sequence $BCL2FASTQ_HOME/share/bcl2fastq-1.8.4/adapters/TruSeq_r2.fa --input-dir $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls --sample-sheet $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv 
#$CASAVA_HOME/bin/configureBclToFastq.pl --fastq-cluster-count 0 --mismatches 0 --no-eamss --input-dir $TMPDIR/$RUN_NAME/Data/Intensities/BaseCalls --sample-sheet $TMPDIR/$RUN_NAME/$FLOWCELL_ID.csv 

echo ""
echo "================================================================================================"
echo ""

echo "`$NOW`running Bcl->fastq conversion conversion..."
cd $TMPDIR/$RUN_NAME/Unaligned		#changing to the 'Unaligned' sub-folder of the project to configure


#The lines commented out below were meant to eanble us to run the make function per read, but we abandoned that when it became apparent that Casava 1.8.2 doesn't allow that kind of action. As a note, when the script was run in that manner,  for make ...r2, the script run smoothly, the log files indicated that it was interpreted as read1, except that in the end no read-2 fastq file was generated
#MAKE_OPTIONS="$THREADS r1"
#if ["$READ" -eq "2"]
#then
#	MAKE_OPTIONS="$THREADS r2"
#fi
MAKE_OPTIONS=$THREADS

make -j $MAKE_OPTIONS

echo ""
echo "================================================================================================"
echo ""

#copy fastq files to raw data folder


lane_idxLength=`echo $PATH_SAMPLE_SHEET  | cut -d "/" -f9 | cut -d "_" -f2,3`

####  XXXXXXXXXXX 
#undetermined indices fastqs
############################
echo "`$NOW`copying undetermined indices fastq files to $PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME..."

#create output directory
mkdir -m 770 -p $PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices/Sample_lane${ILANE}

#copy files
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/Undetermined_indices/Sample_lane${LANE}/*	 $PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices/Sample_lane${ILANE}
chmod -R 770 $PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices/Sample_lane${ILANE}

echo "`$NOW`copying sample fastq files, md5 checksums and sample sheets to $PATH_RAWDATA_DIR..."

#sample fastqs
##############

#iterate over project folders
for PROJECT_DIR in `ls --color=never $TMPDIR/$RUN_NAME/Unaligned | grep Project_`

do	

	#...parse project name from folder name	
	PROJECT_NAME=`echo $PROJECT_DIR | perl -pe 's/Project_//'`

	echo "`$NOW`$PROJECT_NAME"
	echo "`$NOW`-------------"
	
	#make destination folders based on project name
	mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_NAME/fastq
	chmod 770 $PATH_RAWDATA_DIR/$PROJECT_NAME

	#for each sample in the project folder...
	for SAMPLE_DIR_NAME in `ls --color=never $TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/`
	do
		
		SAMPLE_DIR_PATH=$TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_DIR_NAME
		
		#...parse sample name
		SAMPLE_NAME=`echo $SAMPLE_DIR_NAME | perl -pe 's/Sample_//'`
		echo "`$NOW`$SAMPLE_NAME"

		#rename sample directory
		mv $TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_DIR_NAME $TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_NAME
		SAMPLE_DIR_PATH=$TMPDIR/$RUN_NAME/Unaligned/$PROJECT_DIR/$SAMPLE_NAME
			
		#make distination folders based on run date and sample name
		mkdir -m 770 -v -p $PATH_RAWDATA_DIR/$PROJECT_NAME/fastq/$RUN_DATE/$SAMPLE_NAME
		chmod 770 $PATH_RAWDATA_DIR/$PROJECT_NAME/fastq/$RUN_DATE
		chmod 770 $PATH_RAWDATA_DIR/$PROJECT_NAME/fastq

		#set destination directory path
		DESTINATION_DIR=$PATH_RAWDATA_DIR/$PROJECT_NAME/fastq/$RUN_DATE/$SAMPLE_NAME

		#store current working directory
		WORKING_DIR=$PWD
			
		#change to sample directory
		cd $SAMPLE_DIR_PATH
			
		#this file contains the sample under the threshold of reads
		echo "" > $PATH_SAMPLE_SHEET.discard
		#for each fastq file...
		for FASTQ_FILE in `ls --color=never *.fastq*.gz`
		do

			#...make fastq output file name
			FASTQ_FILE=`basename $FASTQ_FILE`
			FASTQ_NAME=`echo $FASTQ_FILE | perl -pe "s/^${SAMPLE_NAME}_/${RUN_NAME}_/"`
			# for TEST
			#echo "SAMPLE_NAME  $SAMPLE_NAME"
			#echo "FASTQ_FILE  $FASTQ_FILE"
			#echo "FASTQ_NAME  $FASTQ_NAME"
			
			### checks if name contains NNNN for undeterminated_indices 
			### then create symbolic link to corrisponding file in rawdata/seqrun 
			### directory
			if [[ $FASTQ_FILE == *"_NNNN"* ]]; then
				#get lane and read to identify the fastq file to link
				read_number=`echo $FASTQ_FILE | cut -d'.' -f1|  tr '_' '\n' | tail -2| head -n 1 | sed 's/R//'`
				lane=`echo $FASTQ_FILE | cut -d'.' -f1|  tr '_' '\n' | tail -3| head -n 1 | sed 's/L//'`
				#path2link=$PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices${ILANE}/Sample_lane$((10#$lane))
				path2link=$PATH_RAWDATA_DIR/seqrun/fastq/$RUN_NAME/Undetermined_indices/Sample_lane$ILANE
				fastq_orign=`ls  $path2link | grep R${read_number}`
				ln -s $path2link/$fastq_orign $FASTQ_NAME
				# for TEST
				#echo "RAW_READ $read_number" 
				#echo "RAW_LANE $lane" 
				#echo "fastq_orign $fastq_orign"
			else
				#rename fastq file
				mv $FASTQ_FILE $FASTQ_NAME
			fi
			
			echo -n "`$NOW`checking fastq integrity..."
			gzip -t $FASTQ_NAME


			#XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX   
			echo "`$NOW` counting number of reads for ... $FASTQ_NAME:$num_reads "	
			num_reads=`gunzip -c  $FASTQ_NAME| awk 'NR == 1 || (NR-1) % 4 == 0' | wc -l`
			sample_row=`grep ",$LANE,$SAMPLE_NAME" $PATH_SAMPLE_SHEET`	
			expected_num_reads=`echo $sample_row  | cut -d "," -f4 | cut -d ":" -f5 | perl -pe 's/\s//g'`
			echo "`$NOW` expected number of reads for lane $LANE and $SAMPLE_NAME. $FASTQ_NAME:$expected_num_reads "
			if [ "$num_reads" -ge "$expected_num_reads" ]; then
				echo "$SAMPLE_NAME OK"

			else
				echo $num_reads$sample_row >> $PATH_SAMPLE_SHEET.discard
				echo "$SAMPLE_NAME KO"
			fi
			
			echo "`$NOW`generating md5 checksum..."
			#generate md5 sum
			md5sum $FASTQ_NAME > $FASTQ_NAME.md5
			
			#copy files
			echo "`$NOW`copying files..."
			#fastq
			echo "`$NOW`$FASTQ_NAME -> $DESTINATION_DIR"
			# added -a option to preserv symbolic links
			cp -av $FASTQ_NAME $DESTINATION_DIR/ 				
			chmod 660 $DESTINATION_DIR/$FASTQ_NAME

			#md5
			echo "`$NOW`$FASTQ_NAME.md5 -> $DESTINATION_DIR"
			cp -v $FASTQ_NAME.md5 $DESTINATION_DIR/ 				
			chmod 660 $DESTINATION_DIR/$FASTQ_NAME.md5

		done

		#copy sample sheet
		echo "`$NOW`SampleSheet.csv $DESTINATION_DIR/SampleSheet.$FLOWCELL_ID.$LANE.csv"
		cp -v SampleSheet.csv $DESTINATION_DIR/SampleSheet.$FLOWCELL_ID.$LANE.csv
		chmod 660 $DESTINATION_DIR/SampleSheet.$FLOWCELL_ID.$LANE.csv
		
		#return to current working directory
		cd $WORKING_DIR
				
	done
	
	echo "`$NOW`-------------"	

done

echo ""
echo "================================================================================================"
echo ""



## adding html for lanes statistics
#scp $PATH_TEMPLATE_HTM/index.html $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/ > /dev/null 2>&1


#copying configuration files and stats
#echo "`$NOW`copying configuration files and stats to $PATH_RUN_DIR/lane${LANE}..."

#create output directory
mkdir -m 770 -p $PATH_RUN_DIR/lane${lane_idxLength}

cp -v -r $TMPDIR/$RUN_NAME/Unaligned/DemultiplexConfig.xml $PATH_RUN_DIR/lane${lane_idxLength}/
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/DemultiplexedBustardConfig.xml $PATH_RUN_DIR/lane${lane_idxLength}/
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/DemultiplexedBustardSummary.xml $PATH_RUN_DIR/lane${lane_idxLength}/
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/Makefile $PATH_RUN_DIR/lane${lane_idxLength}/
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/SampleSheet.mk $PATH_RUN_DIR/lane${lane_idxLength}/
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/support.txt $PATH_RUN_DIR/lane${lane_idxLength}/

chmod 660 $PATH_RUN_DIR/lane${lane_idxLength}/*

echo "`$NOW`copying stats to $PATH_RESULTS_DIR..."
mkdir -m 770 -p $PATH_RESULTS_DIR/lane${lane_idxLength}
cp -v -r $TMPDIR/$RUN_NAME/Unaligned/Basecall_Stats_* $PATH_RESULTS_DIR/lane${lane_idxLength}/
chmod 770 $PATH_RESULTS_DIR/lane${lane_idxLength}/Basecall_Stats_*

echo "`${NOW}`deploying stats to $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/lane${lane_idxLength}..."
ssh $DEPLOYMENT_SERVER "mkdir -p -m 775 $DEPLOYMENT_PATH/lane${lane_idxLength}"  > /dev/null 2>&1

scp -r $TMPDIR/$RUN_NAME/Unaligned/Basecall_Stats_*/Plots $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/lane${lane_idxLength}/  > /dev/null 2>&1
scp -r $TMPDIR/$RUN_NAME/Unaligned/Basecall_Stats_*/css $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/lane${lane_idxLength}/  > /dev/null 2>&1
scp $TMPDIR/$RUN_NAME/Unaligned/Basecall_Stats_*/All.htm $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/lane${lane_idxLength}/  > /dev/null 2>&1
scp $TMPDIR/$RUN_NAME/Unaligned/Basecall_Stats_*/IVC.htm $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/lane${lane_idxLength}/  > /dev/null 2>&1
scp $TMPDIR/$RUN_NAME/Unaligned/Basecall_Stats_*/Demultiplex_Stats.htm $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/lane${lane_idxLength}/  > /dev/null 2>&1

ssh $DEPLOYMENT_SERVER "chmod 775 $DEPLOYMENT_PATH/lane${lane_idxLength}/Plots" > /dev/null 2>&1
ssh $DEPLOYMENT_SERVER "chmod 775 $DEPLOYMENT_PATH/lane${lane_idxLength}/css" > /dev/null 2>&1
ssh $DEPLOYMENT_SERVER "chmod 664 $DEPLOYMENT_PATH/lane${lane_idxLength}/Plots/*"  > /dev/null 2>&1
ssh $DEPLOYMENT_SERVER "chmod 664 $DEPLOYMENT_PATH/lane${lane_idxLength}/css/*"  > /dev/null 2>&1
ssh $DEPLOYMENT_SERVER "chmod 664 $DEPLOYMENT_PATH/lane${lane_idxLength}/All.htm"  > /dev/null 2>&1
ssh $DEPLOYMENT_SERVER "chmod 664 $DEPLOYMENT_PATH/lane${lane_idxLength}/IVC.htm"  > /dev/null 2>&1
ssh $DEPLOYMENT_SERVER "chmod 664 $DEPLOYMENT_PATH/lane${lane_idxLength}/Demultiplex_Stats.htm"  > /dev/null 2>&1


#debugging
##########

ls -al $TMPDIR/*

echo ""

ls -al $TMPDIR/$RUN_NAME/Unaligned/*

echo ""

ls -al $TMPDIR/$RUN_NAME/Unaligned/*/*

echo ""

du -sh $TMPDIR
