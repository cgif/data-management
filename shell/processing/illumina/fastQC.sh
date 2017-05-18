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

#CONFIGURATION
##############

#path to reads fastq file
PROJECT_NAME=#projectName

#deployment
DEPLOYMENT_SERVER=#deploymentServerName
DEPLOYMENT_BASE_DIR=#deploymentBaseDir

DATA_VOL_IGF=#dataVolIgf
SEQRUN_NAME=#seqrunName
SEQRUN_DATE=#seqrunDate
FASTQC_SCRIPT_DIR=#fastqcScriptDir
WORKFLOW_REPO_DIR=#workflowRepoDir

SLACK_URL=https://slack.com/api/chat.postMessage
SLACK_OPT="-d 'channel'='C4W5G8550' -d 'username'='igf_bot'"
SLACK_TOKEN=#slackToken

TODAY=`date +%Y-%m-%d`

############################################
function fastqcSubmit {
  local path_qc_report_dir=$1
  local deployment_path=$2
  local path_fastq_read1=$3
  local path_fastq_read2=$4

  local single_read='F'

  local fastq_read1=`basename $path_fastq_read1`
  if [ "$path_fastq_read2" != "" ]; then
    local fastq_read2=`basename $path_fastq_read2`
  fi

  if [ ! -s $path_fastq_read1 ]; then
    msg="fastq1 is missing, aborting process"
    res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
    exit 1
  fi

  #create temporary QC report output directory
  rm -rf $TMPDIR/qc
  rm -rf $TMPDIR/fastq
  mkdir -m 770 -p $TMPDIR/qc
  mkdir -m 770 -p $TMPDIR/fastq

  #copy fastqs to tmp space
  cp $path_fastq_read1 $TMPDIR/fastq/$fastq_read1
  if [ $? -ne "0" ]; then
    msg="ERROR while copying R1 $fastq_read1"
    res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
    exit 1
  fi
  
  # checks if FASTQ_READ2 exists. If doesn't exists assume RUN sigle read
  if [ "$path_fastq_read2" == "" ]; then
    single_read="T"
  fi

  if [[ "$single_read" == "F" ]]; then
    cp $path_fastq_read2 $TMPDIR/fastq/$fastq_read2
    if [ $? -ne "0" ]; then
      msg="ERROR while copying R2 $fastq_read2"
      res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
      exit 1
    fi
  fi
           
  #check if mate file found and the number of lines in mate files is the same
  gzip -t $TMPDIR/fastq/$fastq_read1
  if [ $? -ne "0" ]; then
    msg="ERROR:File $fastq_read1 is corrupted. Skipped" 
    res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  fi

  if [[ "$single_read" == "F" ]]; then
    gzip -t $TMPDIR/fastq/$fastq_read2
    if [ $? -ne "0" ]; then
      msg="ERROR:File $FASTQ_READ2 is corrupted. Skipped." 
      res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
    else 
      local count_lines_read1=`gzip -d -c $TMPDIR/fastq/$fastq_read1 | wc -l | cut -f 1 -d ' '`
      local count_lines_read2=`gzip -d -c $TMPDIR/fastq/$fastq_read2 | wc -l | cut -f 1 -d ' '`

      if [ "$count_lines_read1" -ne "$count_lines_read2" ]; then
        msg="ERROR:Unequal number of lines in the mate files. Skipped." 
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
      else
        $FASTQC_HOME/bin/fastqc -o $TMPDIR/qc --noextract --nogroup  $TMPDIR/fastq/$fastq_read1
	$FASTQC_HOME/bin/fastqc -o $TMPDIR/qc --noextract --nogroup  $TMPDIR/fastq/$fastq_read2
      fi	
    fi
  else
    #run FastQC for single reads
    $FASTQC_HOME/bin/fastqc -o $TMPDIR/qc --noextract --nogroup  $TMPDIR/fastq/$fastq_read1
  fi

  # if Undetermined fastq file
  if [[ $fastq_read1 == *"Undetermined"* ]]
  then 
    #try to find the correct barcode
    barcodes=`echo $fastq_read1 | perl -pe 's/_R1//g'`
    zcat $TMPDIR/fastq/$fastq_read1|awk '{if( /^\@/ ){ FS=":"; if( $10){print $10 }}}'|sort |uniq -c|sort -nrk1,1 > $TMPDIR/qc/${barcodes}.txt

    #copies barcode file in the results directory
    cp $TMPDIR/qc/${barcodes}.txt $PATH_QC_REPORT_DIR
  fi

  #copy results to output folder
  cp $TMPDIR/qc/*zip $PATH_QC_REPORT_DIR
  chmod 660 $PATH_QC_REPORT_DIR/*zip

  ssh $DEPLOYMENT_SERVER "mkdir -p -m 775 $deployment_path" < /dev/null

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
    scp -r $TMPDIR/$report_dir $DEPLOYMENT_SERVER:$deployment_path/  < /dev/null 
    ssh $DEPLOYMENT_SERVER "chmod 775 $deployment_path/$report_dir" < /dev/null
    ssh $DEPLOYMENT_SERVER "chmod 775 $deployment_path/$report_dir/*"  < /dev/null
    ssh $DEPLOYMENT_SERVER "chmod 775 $deployment_path/$report_dir/*/*"  < /dev/null

    mkdir -p -m 770 $path_qc_report_dir/$report_dir
    cp $TMPDIR/$report_dir/*.txt  $path_qc_report_dir/$report_dir
    chmod 660 $path_qc_report_dir/$report_dir/*.txt

  done
}
############################################
# PROJECT

# Create and set permissions for run directory
project_runs_dir=$DATA_VOL_IGF/runs/$PROJECT_NAME/fastqc/$TODAY
mkdir -m 770 -p $project_runs_dir
ms_runs_dir=$project_runs_dir/multisample
mkdir -m 770 -p $ms_runs_dir
chmod -R 770 $DATA_VOL_IGF/runs/$PROJECT_NAME

# Create and set permissions for results project parent directory
project_results_dir=$DATA_VOL_IGF/results/$PROJECT_NAME/fastqc/$SEQRUN_DATE

mkdir -m 770 -p $project_results_dir/multisample
chmod -R 770 $DATA_VOL_IGF/results/$PROJECT_NAME

# Create deployment dir and copy required files
fastqc_summary_deployment=$DEPLOYMENT_BASE_DIR/project/$PROJECT_NAME/fastqc/$SEQRUN_DATE
ssh $DEPLOYMENT_SERVER "mkdir -p -m 775 $fastqc_summary_deployment"  < /dev/null
ssh $DEPLOYMENT_SERVER "chmod -R 775 $DEPLOYMENT_BASE_DIR/project/$PROJECT_NAME"  < /dev/null
scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/error.png $DEPLOYMENT_SERVER:$fastqc_summary_deployment/ < /dev/null
scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/tick.png $DEPLOYMENT_SERVER:$fastqc_summary_deployment/ < /dev/null
scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/warning.png $DEPLOYMENT_SERVER:$fastqc_summary_deployment/ < /dev/null
scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/igf.png $DEPLOYMENT_SERVER:$fastqc_summary_deployment/ < /dev/null
ssh $DEPLOYMENT_SERVER "chmod -R 664 $fastqc_summary_deployment/*png" < /dev/null

msg="Starting Fastqc check for project $PROJECT_NAME"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`


for lane_dir in `find $DATA_VOL_IGF/rawdata/$PROJECT_NAME/fastq/$SEQRUN_DATE/ -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
do
  # LANE

  for sample_name in `find $DATA_VOL_IGF/rawdata/$PROJECT_NAME/fastq/$SEQRUN_DATE/$lane_dir -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
  do
    # SAMPLE
   
    path_reads_dir=$DATA_VOL_IGF/rawdata/$PROJECT_NAME/fastq/$SEQRUN_DATE/$lane_dir/$sample_name

    # Go to next sample if its Reports or Stats dir

    path_reads_dir_basename=`basename $path_reads_dir`
    if [ $path_reads_dir_basename == 'Stats' ] || [ $path_reads_dir_basename == 'Reports' ]; then
      continue
    fi

    project_runs_dir=$DATA_VOL_IGF/runs/$PROJECT_NAME/fastqc/$TODAY
    project_results_dir=$DATA_VOL_IGF/results/$PROJECT_NAME/fastqc/$SEQRUN_DATE
    qc_report_outputdir=$project_results_dir/$sample_name
    ms_runs_dir=$project_runs_dir/multisample

    mkdir -m 770 -p $qc_report_outputdir
    
    # Deployment directories for the QC reports for each file
    fastqc_deployment_path=$DEPLOYMENT_BASE_DIR/project/$PROJECT_NAME/fastqc/$SEQRUN_DATE/$sample_name
    fastqc_summary_deployment=$DEPLOYMENT_BASE_DIR/project/$PROJECT_NAME/fastqc/$SEQRUN_DATE

    sample_runs_dir=$project_runs_dir/$sample_name
    mkdir -m 770 -p $sample_runs_dir

    # Hack for checking NextSeq dir, replace it with db check
    if [[ $SEQRUN_NAME =~ _NB501820_ ]];then
      declare -a files=`find $path_reads_dir -type f -name '*fastq.gz' -exec basename {} \;`
      declare -a lanes=`echo "("; echo "${files[@]}"|sed 's/.*_\(L00[1-9]\)_.*/\1/g'|sort -u; echo ")"`
      
      for lane in ${lanes[@]}
      do
        fastq_arr=''
        declare -a fastq_arr=`echo "("; echo "${files[@]}"|grep $lane; echo ")"`

        if [ "${#fastq_arr[@]}" -eq 0 ];then
          msg="can not find fastq files for sample $sample_name lane $lane, aborting process"
          res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
          exit 1
        fi

        fastq_read1=''
        fastq_read2=''
 
        # Check fastq and submit fastqc jobs for NextSeq platform
        if [ "${#fastq_arr[@]}" -eq 1 ];then
          fastq_read1=${fastq_arr[0]}
          fastqcSubmit $qc_report_outputdir $fastqc_deployment_path $path_reads_dir/$fastq_read1 $fastq_read2
        elif [ "${#fastq_arr[@]}" -eq 2 ];then
          fastq_read1=${fastq_arr[0]}
          fastq_read2=${fastq_arr[1]}
          fastqcSubmit $qc_report_outputdir $fastqc_deployment_path $path_reads_dir/$fastq_read1 $path_reads_dir/$fastq_read2
        else
          msg="can not assign fastq files type for files in $path_reads_dir; aborting process"
          res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
          exit 1
        fi
      done

    else
      # Assign fastq files for other illumina platforms
      fastq_arr=''
  
      declare -a fastq_arr=$( echo "("; find $path_reads_dir -type f -name '*fastq.gz' -exec basename {} \; ; echo ")")
      fastq_read1=''
      fastq_read2=''
    
      if [ "${#fastq_arr[@]}" -eq 0 ];then
        msg="can not find fastq files for sample $sample_name, aborting process"
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
        exit 1
      fi

      # Check fastq and submit fastqc jobs for other platform
      if [ "${#fastq_arr[@]}" -eq 1 ];then
        fastq_read1=${fastq_arr[0]}
        fastqcSubmit $qc_report_outputdir $fastqc_deployment_path $path_reads_dir/$fastq_read1 $fastq_read2
      elif [ "${#fastq_arr[@]}" -eq 2 ];then
        fastq_read1=${fastq_arr[0]}
        fastq_read2=${fastq_arr[1]}
        fastqcSubmit $qc_report_outputdir $fastqc_deployment_path $path_reads_dir/$fastq_read1 $path_reads_dir/$fastq_read2
      else
        msg="can not assign fastq files type for files in $path_reads_dir; aborting process"
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
        exit 1
      fi
    fi
            
  done

  # LANE
  # Copy demultiplexing reports
  ssh $DEPLOYMENT_SERVER "mkdir -m 770 -p $DEPLOYMENT_BASE_DIR/seqrun/$SEQRUN_NAME/bcl2fastq/$TODAY/lane${lane_dir}"
  scp -r $DATA_VOL_IGF/rawdata/$PROJECT_NAME/fastq/$SEQRUN_DATE/$lane_dir/Reports/html $DEPLOYMENT_SERVER:$DEPLOYMENT_BASE_DIR/seqrun/$SEQRUN_NAME/bcl2fastq/$TODAY/lane${lane_dir}

  msg="Demultiplexing stats for run $SEQRUN_NAME lane ${lane_dir} is available, http://eliot.med.ic.ac.uk/report/seqrun/$SEQRUN_NAME/bcl2fastq/$TODAY/lane${lane_dir}"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`

  # FastQC jobs for unassigned reads
  seqrun_runs_dir=$DATA_VOL_IGF/runs/seqrun/$SEQRUN_NAME/fastqc/$TODAY
  seqrun_results_dir=$DATA_VOL_IGF/results/seqrun/$SEQRUN_NAME/fastqc/$SEQRUN_DATE
  ms_runs_dir=$seqrun_runs_dir/multisample
  mkdir -m 770 -p $ms_runs_dir
  chmod -R 770 $DATA_VOL_IGF/runs/seqrun/$SEQRUN_NAME

  sample_runs_dir=$seqrun_runs_dir/$lane_dir
  mkdir -m 770 -p $sample_runs_dir
  uqc_report_outputdir=$seqrun_results_dir/$lane_dir
  ufastqc_deployment_path=$DEPLOYMENT_BASE_DIR/seqrun/$SEQRUN_NAME/fastqc/$SEQRUN_DATE/$lane_dir
  ufastqc_summary_deployment=$DEPLOYMENT_BASE_DIR/seqrun/$SEQRUN_NAME/fastqc/$SEQRUN_DATE
  upath_reads_dir=$DATA_VOL_IGF/rawdata/seqrun/fastq/$SEQRUN_NAME/Undetermined_indices/Sample_lane${lane_dir}
 
  # Hack for checking NextSeq dir, replace it with db check
  if [[ $SEQRUN_NAME =~ _NB501820_ ]];then
    declare -a files=`find $upath_reads_dir -type f -name '*fastq.gz' -exec basename {} \;`
    declare -a lanes=`echo "("; echo "${files[@]}"|sed 's/.*_\(L00[1-9]\)_.*/\1/g'|sort -u; echo ")"`
    
    for lane in ${lanes[@]}
    do
      ufastq_arr=''
      declare -a ufastq_arr=`echo "("; echo "${files[@]}"|grep $lane; echo ")"`
  
      ufastq_read1=''
      ufastq_read2=''
 
      if [ "${#ufastq_arr[@]}" -eq 0 ];then
        msg="can not find undetermined fastq files for lane $lane_dir, aborting process"
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
        exit 1
      fi

      # Check fastq and submit fastqc jobs for NextSeq platform  
      if [ "${#ufastq_arr[@]}" -eq 1 ];then
        ufastq_read1=${ufastq_arr[0]}
        fastqcSubmit $uqc_report_outputdir $ufastqc_deployment_path $upath_reads_dir/$ufastq_read1 $ufastq_read2
      elif [ "${#ufastq_arr[@]}" -eq 2 ];then
        ufastq_read1=${ufastq_arr[0]}
        ufastq_read2=${ufastq_arr[1]}
        fastqcSubmit $uqc_report_outputdir $ufastqc_deployment_path $upath_reads_dir/$ufastq_read1 $upath_reads_dir/$ufastq_read2
      else
        msg="can not assign fastq files type for files in $upath_reads_dir, aborting process"
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
        exit 1
      fi
    done
  else
    # Submit jobs for other illumina platform
    ufastq_arr=''
    declare -a ufastq_arr=$( echo "("; find $upath_reads_dir -type f -name '*fastq.gz' -exec basename {} \; ; echo ")")
    ufastq_read1=''
    ufastq_read2=''

    if [ "${#ufastq_arr[@]}" -eq 0 ];then
        msg="can not find undetermined fastq files for lane $lane_dir, aborting process"
        res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
        exit 1
    fi

    # Check fastq and submit fastqc jobs for other platform  
    if [ "${#ufastq_arr[@]}" -eq 1 ];then
      ufastq_read1=${ufastq_arr[0]}
      fastqcSubmit $uqc_report_outputdir $ufastqc_deployment_path $upath_reads_dir/$ufastq_read1 $ufastq_read2
    elif [ "${#ufastq_arr[@]}" -eq 2 ];then
      ufastq_read1=${ufastq_arr[0]}
      ufastq_read2=${ufastq_arr[1]}
      fastqcSubmit $uqc_report_outputdir $ufastqc_deployment_path $upath_reads_dir/$ufastq_read1 $upath_reads_dir/$ufastq_read2
    else
      msg="can not assign fastq files type for files in $upath_reads_dir, aborting process"
      res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
      exit 1
    fi
  fi

  #submit summary job for unassigned reads
  #create summary directory on deployment server
  fastqc_summary_deployment=$DEPLOYMENT_BASE_DIR/seqrun/$SEQRUN_NAME/fastqc/$SEQRUN_DATE
  ssh $DEPLOYMENT_SERVER "mkdir -p -m 775 $fastqc_summary_deployment" < /dev/null
  ssh $DEPLOYMENT_SERVER "chmod -R 775 $DEPLOYMENT_BASE_DIR/seqrun/$SEQRUN_NAME" < /dev/null
  scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/error.png $DEPLOYMENT_SERVER:$ufastqc_summary_deployment/ < /dev/null
  scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/tick.png $DEPLOYMENT_SERVER:$ufastqc_summary_deployment/ < /dev/null
  scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/warning.png $DEPLOYMENT_SERVER:$ufastqc_summary_deployment/ < /dev/null
  scp -r ${WORKFLOW_REPO_DIR}/shell/resources/images/igf.png $DEPLOYMENT_SERVER:$ufastqc_summary_deployment/ < /dev/null
  ssh $DEPLOYMENT_SERVER "chmod -R 664 $ufastqc_summary_deployment/*png" < /dev/null

  #create summary script from template
  seqrun_runs_dir=$DATA_VOL_IGF/runs/seqrun/$SEQRUN_NAME/fastqc/$TODAY
  seqrun_results_dir=$DATA_VOL_IGF/results/seqrun/$SEQRUN_NAME/fastqc/$SEQRUN_DATE
  seqrun_rawdata_dir=$DATA_VOL_IGF/rawdata/seqrun/fastq/$SEQRUN_NAME
  ms_runs_dir=$seqrun_runs_dir/multisample
  ms_results_dir=$seqrun_results_dir/multisample

  mkdir -m 770 -p $ms_runs_dir
  mkdir -m 770 -p $ms_results_dir
  chmod -R 770 $DATA_VOL_IGF/runs/seqrun/$SEQRUN_NAME
  chmod -R 770 $DATA_VOL_IGF/results/seqrun/$SEQRUN_NAME
  chmod -R 770 $DATA_VOL_IGF/rawdata/seqrun/fastq/$SEQRUN_NAME

  summary_path=$ms_runs_dir/summary.$SEQRUN_NAME.pl
  cp $WORKFLOW_REPO_DIR/shell/pre_processing/fastqc/summary_fastqc.pl $summary_path
  chmod 770 $summary_path
  path_fastq_dir=$seqrun_rawdata_dir/Undetermined_indices

  #configure summary script, it will be executed from fastqc script
  sed -i -e "s|#pathReadsFastq|${path_fastq_dir}|" $summary_path
  sed -i -e "s|#pathReportsDir|${seqrun_results_dir}|" $summary_path
  sed -i -e "s|#pathRunsDir|${seqrun_runs_dir}|" $summary_path
  sed -i -e "s|#pathMSReportsDir|${ms_results_dir}|" $summary_path
  sed -i -e "s|#deploymentServer|$DEPLOYMENT_SERVER|" $summary_path
  sed -i -e "s|#summaryDeployment|${ufastqc_summary_deployment}|" $summary_path
  log_output_path=`echo $summary_path | perl -pe 's/\.pl/\.log/g'`

  # run summary script per lane
  perl $summary_path 2> $log_output_path
  retval=$?
  if [ "$retval" -ne 0 ]; then
    msg="got error while running summary generation step for $SEQRUN_NAME : $lane_dir , aborting process"
    res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
    exit 1
  fi

done

# PROJECT
#create summary script from template

project_rawdata_dir=$DATA_VOL_IGF/rawdata/$PROJECT_NAME/fastq/$SEQRUN_DATE
project_runs_dir=$DATA_VOL_IGF/runs/$PROJECT_NAME/fastqc/$TODAY
project_results_dir=$DATA_VOL_IGF/results/$PROJECT_NAME/fastqc/$SEQRUN_DATE
ms_runs_dir=$project_runs_dir/multisample
ms_results_dir=$project_results_dir/multisample
summary_path=$ms_runs_dir/summary.$SEQRUN_NAME.pl

mkdir -p -m 770 $ms_runs_dir
mkdir -p -m 770 $ms_results_dir
cp $WORKFLOW_REPO_DIR/shell/pre_processing/fastqc/summary_fastqc.pl $summary_path
chmod 770 $summary_path

path_fastq_dir=$project_rawdata_dir
fastqc_summary_deployment=$DEPLOYMENT_BASE_DIR/project/$PROJECT_NAME/fastqc/$SEQRUN_DATE

#configure summary script, it will be executed from fastqc script
sed -i -e "s|#pathReadsFastq|${path_fastq_dir}|" $summary_path
sed -i -e "s|#pathReportsDir|${project_results_dir}|" $summary_path
sed -i -e "s|#pathRunsDir|${project_runs_dir}|" $summary_path
sed -i -e "s|#pathMSReportsDir|${ms_results_dir}|" $summary_path
sed -i -e "s|#deploymentServer|$DEPLOYMENT_SERVER|" $summary_path
sed -i -e "s|#summaryDeployment|${fastqc_summary_deployment}|" $summary_path

log_output_path=`echo $summary_path | perl -pe 's/\.pl/\.log/g'`

# run summary script per lane
perl $summary_path 2> $log_output_path

retval=$?
if [ "$retval" -ne 0 ]; then
  msg="got error while running summary generation step for $PROJECT_NAME , aborting process"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi


# MultiQC
multiqc_path=$ms_runs_dir/multiqc.$SEQRUN_NAME.sh
cp $WORKFLOW_REPO_DIR/shell/pre_processing/fastqc/multiqc.sh $multiqc_path
chmod 770 $multiqc_path

#configure multiqc script
sed -i -e "s|#pathReadsFastq|${path_fastq_dir}|" $multiqc_path
sed -i -e "s|#pathReportsDir|${project_results_dir}|" $multiqc_path
sed -i -e "s|#pathRunsDir|${project_runs_dir}|" $multiqc_path
sed -i -e "s|#pathMSReportsDir|${ms_results_dir}|" $multiqc_path
sed -i -e "s|#deploymentServer|$DEPLOYMENT_SERVER|" $multiqc_path
sed -i -e "s|#summaryDeployment|${fastqc_summary_deployment}|" $multiqc_path

# submit multiqc job
ms_log_path=`echo $multiqc_path | perl -pe 's/\.sh/\.log/g'`

bash $multiqc_path 2> $ms_log_path

retval=$?
if [ "$retval" -ne 0 ]; then
  msg="got error while running multiqc generation step for $PROJECT_NAME , aborting process"
  res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`
  exit 1
fi

msg="Fastqc report for $PROJECT_NAME  $SEQRUN_DATE is available, http://eliot.med.ic.ac.uk/report/project/$PROJECT_NAME/fastqc/$SEQRUN_DATE"
res=`echo "curl $SLACK_URL -X POST $SLACK_OPT -d 'token'='$SLACK_TOKEN' -d 'text'='$msg'"|sh`


