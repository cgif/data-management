#!/bin/bash

#
# script to run FastQC on a fastq file
# on cx1
#

#PBS -l walltime=24:00:00
#PBS -l select=1:ncpus=1:mem=500mb

#PBS -m ea
#PBS -M igf@imperial.ac.uk
#PBS -j oe

#PBS -q pqcgi

module load fastqc/0.11.2

#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`

#CONFIGURATION
##############

#path to reads fastq file
PROJECT_NAME=#projectName

#deployment
DEPLOYMENT_SERVER=#deploymentServer
DEPLOYMENT_PATH=#deploymentPath
SUMMARY_PATH=#summaryPath

############################################

# Create and set permissions for run directory
project_runs_dir=$DATA_VOL_IGF/runs/$project/fastqc/$TODAY
mkdir -m 770 -p $project_runs_dir
ms_runs_dir=$project_runs_dir/multisample
mkdir -m 770 -p $ms_runs_dir
chmod -R 770 $DATA_VOL_IGF/runs/$project

# Create and set permissions for results project parent directory
project_results_dir=$DATA_VOL_IGF/results/$project/fastqc/$SEQRUN_DATE

mkdir -m 770 -p $project_results_dir/multisample
chmod -R 770 $DATA_VOL_IGF/results/$project


for lane_dir in `find $DATA_VOL_IGF/rawdata/$project/fastq/$SEQRUN_DATE/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
do
  # LANE

  for sample_name in `find $DATA_VOL_IGF/rawdata/$project/fastq/$SEQRUN_DATE/$lane_dir -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
  do
    # SAMPLE
   
    path_reads_dir=$DATA_VOL_IGF/rawdata/$project/fastq/$SEQRUN_DATE/$lane_dir/$sample_name

    # Go to next sample if its Reports or Stats dir

    path_reads_dir_basename=`basename $path_reads_dir`
    if [ $path_reads_dir_basename == 'Stats' ] || [ $path_reads_dir_basename == 'Reports' ]; then
      continue
    fi

    project_runs_dir=$DATA_VOL_IGF/runs/$project/fastqc/$TODAY
    project_results_dir=$DATA_VOL_IGF/results/$project/fastqc/$SEQRUN_DATE
    qc_report_outputdir=$project_results_dir/$sample_name
    ms_runs_dir=$project_runs_dir/multisample

    mkdir -m 770 -p $qc_report_outputdir
    
    # Deployment directories for the QC reports for each file
    fastqc_deployment_path=$DEPLOYMENT_BASE_DIR/project/$project/fastqc/$SEQRUN_DATE/$sample_name
    fastqc_summary_deployment=$DEPLOYMENT_BASE_DIR/project/$project/fastqc/$SEQRUN_DATE

    sample_runs_dir=$project_runs_dir/$sample_name
    mkdir -m 770 -p $sample_runs_dir
  
    # Assign fastq files
    fastq_arr=''
  
    declare -a fastq_arr=$( echo "("; find $path_reads_dir -type f -name '*fastq.gz' -exec basename {} \; ; echo ")")
    fastq_read1=''
    fastq_read2=''
    
    if [ ${#fastq_arr[@]} -eq 1 ];then
      fastq_read2=${fastq_arr[0]}
    elif [ ${#fastq_arr[@]} -eq 2 ];then
      fastq_read1=${fastq_arr[0]}
      fastq_read2=${fastq_arr[1]}
    else
      msg="couldn't assign fastq files type for files in $path_reads_dir; aborting process"
      res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
      exit 1
    fi

    fastQC_script_path=$sample_runs_dir/fastQC.$fastq_read1.sh
    cp $FASTQC_SCRIPT_DIR/fastQC.sh $fastQC_script_path
    chmod 770 $fastQC_script_path

        
  done

done

############################################
function fastqcSubmit {
  local path_qc_report_dir=$1
  local path_fastq_read1=$2
  local path_fastq_read2=$3

  local single_read='F'

  local fastq_read1=`basename $path_fastq_read1`
  local fastq_read2=`basename $path_fastq_read2`

  #create temporary QC report output directory
  rm -rf $TMPDIR/qc
  mkdir $TMPDIR/qc

  #copy fastqs to tmp space
  cp $path_fastq_read1 $TMPDIR/$fastq_read1

  # checks if FASTQ_READ2 exists. If doesn't exists assume RUN sigle read
  if [ ! -f "$fastq_read2" ]; then
    $single_read="T"
  fi

  if [[ "$single_read" == "F" ]]; then
    cp $path_fastq_read2 $TMPDIR/$fastq_read2
  fi
           
  #check if mate file found and the number of lines in mate files is the same
  gzip -t $TMPDIR/$fastq_read1
  if [ $? -ne "0" ]; then
    msg="ERROR:File $fastq_read1 is corrupted. Skipped" 
    res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  fi

  if [[ "$single_read" == "F" ]]; then
    gzip -t $TMPDIR/$fastq_read2
    if [ $? -ne "0" ]; then
      msg="ERROR:File $FASTQ_READ2 is corrupted. Skipped." 
      res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
    else 
      local count_lines_read1=`gzip -d -c $TMPDIR/$fastq_read1 | wc -l | cut -f 1 -d ' '`
      local count_lines_read2=`gzip -d -c $TMPDIR/$fastq_read2 | wc -l | cut -f 1 -d ' '`

      if [ "$count_lines_read1" -ne "$count_lines_read2" ]; then
        msg="ERROR:Unequal number of lines in the mate files. Skipped." 
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
      else
        $FASTQC_HOME/bin/fastqc -o $TMPDIR/qc --noextract --nogroup  $TMPDIR/$fastq_read1
	$FASTQC_HOME/bin/fastqc -o $TMPDIR/qc --noextract --nogroup  $TMPDIR/$fastq_read2
			
      fi	
    fi
  else
    #run FastQC for single reads
    $FASTQC_HOME/bin/fastqc -o $TMPDIR/qc --noextract --nogroup  $TMPDIR/$fastq_read1
  fi

  # if Undetermined fastq file
  if [[ $fastq_read1 == *"Undetermined"* ]]
  then 
    #try to find the correct barcode
    barcodes=`echo $fastq_read1 | perl -pe 's/_R1//g'`
    zcat $TMPDIR/$fastq_read1|awk '{if( /^\@/ ){ FS=":"; if( $10){print $10 }}}'|sort |uniq -c|sort -nrk1,1 > $TMPDIR/qc/${barcodes}.txt

    #copies barcode file in the results directory
    cp $TMPDIR/qc/${barcodes}.txt $PATH_QC_REPORT_DIR
  fi

  #copy results to output folder
  cp $TMPDIR/qc/*zip $PATH_QC_REPORT_DIR
  chmod 660 $PATH_QC_REPORT_DIR/*zip

  ssh $DEPLOYMENT_SERVER "mkdir -p -m 775 $DEPLOYMENT_PATH" < /dev/null

  for zip in `ls $TMPDIR/qc/*.zip`
  do
    unzip $zip
    local report_dir=`basename $zip .zip`	
    #add to the report the link to the list of samples
    sed -i 's/<ul>/<ul><li><a href=\"\.\.\/\.\.\/\">Home<\/a><\/li>/g' $report_dir/fastqc_report.html
    #if udetermined fastq file add a link in the report to the files listing possible indexes
    if [[ $zip == *"Undetermined"* ]]
    then
      #copies barcode file in the report directory
      cp $TMPDIR/qc/${barcodes}.txt $report_dir
      sed -i 's/<\/ul>/<li><a href=\"'${barcodes}'\.txt">Barcode<\/a><\/li><\/ul>/g' $report_dir/fastqc_report.html
    fi
    scp -r $TMPDIR/$report_dir $DEPLOYMENT_SERVER:$DEPLOYMENT_PATH/  < /dev/null 
    ssh $DEPLOYMENT_SERVER "chmod 775 $DEPLOYMENT_PATH/$report_dir" < /dev/null
    ssh $DEPLOYMENT_SERVER "chmod 775 $DEPLOYMENT_PATH/$report_dir/*"  < /dev/null
    ssh $DEPLOYMENT_SERVER "chmod 775 $DEPLOYMENT_PATH/$report_dir/*/*"  < /dev/null

    mkdir -p -m 770 $path_qc_report_dir/$report_dir
    cp $TMPDIR/$report_dir/*.txt  $path_qc_report_dir/$report_dir
    chmod 660 $path_qc_report_dir/$report_dir/*.txt

  done
}
