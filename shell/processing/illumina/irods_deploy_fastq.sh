#!/bin/bash
#
# script to run irods_deploy_fastq 
#

#PBS -l walltime=72:00:00
#PBS -l select=1:ncpus=1:mem=1024mb

#PBS -m ea
#PBS -M igf@imperial.ac.uk
#PBS -j oe

#PBS -q pqcgi


#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`

############################ XXXXXXXXXXXXXX
DEPLOYMENT_SERVER=eliot.med.ic.ac.uk
DEPLOYMENT_BASE_DIR=/www/html/report/project
DEPLOYMENT_TAR_BASE_DIR=/data/www/html/report/data

#set up script
PATH_PROJECT_TAG_DIR=#pathProjectTagDir
SEQ_RUN_DATE=#seqRunDate
SEQ_RUN_NAME=#seqRunName
RUN_DIR_BCL2FASTQ=#runDirBcl2Fastq
CUSTOMER_FILE_PATH=#customerFilePath
PROJECT_TAG=#projectTag
MAIL_TEMPLATE_PATH=#mailTemplatePath
PATH_TO_DESTINATION=#pathToDestination
USE_IRODS=#useIrods
HIGHTLIGHT="iRODSUserTagging:Star"

IRODS_USER=igf
IRODS_PWD=igf
SEND_EMAIL_SCRIPT=$MAIL_TEMPLATE_PATH/../shell/processing/illumina/send_email.sh
SEND_NOTIFICATION_SCRIPT=$MAIL_TEMPLATE_PATH/../shell/processing/illumina/send_notification.sh

# Set customer info'
customers_info=`grep -w $PROJECT_TAG $CUSTOMER_FILE_PATH/customerInfo.csv`
customer_name=`echo $customers_info|cut -d ',' -f2`
customer_username=`echo $customers_info|cut -d ',' -f3`
customer_passwd=`echo $customers_info|cut -d ',' -f4`
customer_email=`echo $customers_info|cut -d ',' -f5`

if [[ $customer_email != *"@"* ]]; then
        #send email alert...
        echo -e "subject:Sequencing Run $SEQ_RUN_NAME Deploying Warning - the email address for $customer_username is unknown." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
fi

# Check if is internal customer
ldapUser=`ldapsearch -x -h unixldap.cc.ic.ac.uk | grep "uid: $customer_username"`
retval=$?
if [ $retval -ne 0 ]; then
    echo "External customer"
    externalUser="Y"
fi

if [ "$USE_IRODS" = "T" ]; then
  # Check for existing user
  irods_user=`iadmin lu | grep $customer_username | cut -d "#" -f1`#

  # Create account for new user
  if [ "$irods_user" = "" ]; then
    iadmin mkuser $customer_username#igfZone rodsuser

    # Set password for external user
    if [ "$externalUser" = "Y" ]; then
      iadmin moduser $customer_username#igfZone password $customer_passwd
    fi
  fi

  # Set parmissions
  ichmod -M own igf /igfZone/home/$customer_username
  ichmod -r inherit /igfZone/home/$customer_username
fi

# Adding FASTQ FILES To woolfResc
module load irods/4.2.0
iinit igf

# Goto the destination dir
cd $PATH_TO_DESTINATION/$SEQ_RUN_DATE

# Find all lane dirs
for lane_dir in `find .  -mindepth 1 -maxdepth 1 -type d -exec basename {} \;`
do
   seq_run_date_lane=${SEQ_RUN_DATE}_${lane_dir}
   # Create tar files per lane
   tar hcfz ${seq_run_date_lane}.tar.gz  ${lane_dir}

   # Generate an md5 checksum for the tarball
   md5sum ${seq_run_date_lane}.tar.gz > ${seq_run_date_lane}.tar.gz.md5
   chmod 664 ${seq_run_date_lane}.tar.gz ${seq_run_date_lane}.tar.gz.md5

   if [ "$USE_IRODS" = "T" ]; then
     # Creates the deploy structure
     imkdir -p /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE
     ichmod -M own igf /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE
     ichmod -r inherit /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE

     # Set metadata
     imeta add -C /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE run_name $SEQ_RUN_NAME

     # Store file in irods
     iput -k -fP -N 4 -X $PATH_TO_DESTINATION/$SEQ_RUN_DATE/restartFile.$lane_dir --retries 3 -R woolfResc $PATH_TO_DESTINATION/$SEQ_RUN_DATE/${seq_run_date_lane}.tar.gz  /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE

     retval=$?
     if [ $retval -ne 0 ]; then
       echo "`$NOW` ERROR registering sequencing data in IRODS"
       echo -e "subject:Sequencing Data for project $PROJECT_TAG Processing Error. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "igf@ic.ac.uk"
       exit 1
     fi
   else
      # No other option for file transfer
      exit 1
   fi

   # Add md5 value to irods
   iput -fP -R woolfResc $PATH_TO_DESTINATION/${seq_run_date_lane}.tar.gz.md5  /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE

   # Set expire date
   isysmeta mod /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE/${seq_run_date_lane}.tar.gz '+30d'
   imeta add -d /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE/${seq_run_date_lane}.tar.gz "$TODAY - fastq - $PROJECT_TAG" $customer_username $HIGHTLIGHT
   imeta add -d /igfZone/home/$customer_username/$PROJECT_TAG/fastq/$SEQ_RUN_DATE/${seq_run_date_lane}.tar.gz retention "30" "days"

   # Remove tar files
   rm -f ${seq_run_date_lane}.tar.gz ${seq_run_date_lane}.tar.gz.md5
done

# Change dir permission
ichmod -r read $customer_username /igfZone/home/$customer_username/

# Prepare the email to send to the customer
customer_mail=customer_mail.$PROJECT_TAG
if [[ $externalUser == "Y" ]];then
  if [ "$USE_IRODS" = "T" ];then
    cp $MAIL_TEMPLATE_PATH/eirodscustomer_mail.tml $RUN_DIR_BCL2FASTQ/$customer_mail
  else
    cp $MAIL_TEMPLATE_PATH/ecustomer_mail.tml $RUN_DIR_BCL2FASTQ/$customer_mail
  fi
else
  if [ "$USE_IRODS" = "T" ];then
    cp $MAIL_TEMPLATE_PATH/iirodscustomer_mail.tml $RUN_DIR_BCL2FASTQ/$customer_mail
  else
    cp $MAIL_TEMPLATE_PATH/icustomer_mail.tml $RUN_DIR_BCL2FASTQ/$customer_mail
  fi
fi

chmod 770 $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#customerEmail/$customer_email/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#customerName/$customer_name/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#customerUsername/$customer_username/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#passwd/$customer_passwd/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#projectName/$PROJECT_TAG/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#projectRunDate/$SEQ_RUN_DATE/g" $RUN_DIR_BCL2FASTQ/$customer_mail

customer_email=$RUN_DIR_BCL2FASTQ/$customer_mail
send_email_script=$RUN_DIR_BCL2FASTQ/send_email.${PROJECT_TAG}.sh
cp $SEND_EMAIL_SCRIPT $send_email_script
chmod 770 $send_email_script

sed -i -e "s/#customerEmail/${customer_email//\//\\/}/" $send_email_script
sed -i -e "s/#customerUsername/$customer_username/" $send_email_script
log_output_path=`echo $send_email_script | perl -pe 's/\.sh/\.log/g'`
echo -n "" > $log_output_path
echo -n "`$NOW`submitting send email to the customer job: "
echo "$send_email_script"

# Before to send the email to the customer the invoice has to be paid!!!
# Send to the customer
job_id=null
job_id=`qsub -o $log_output_path -j oe $send_email_script`
echo "qsub -o $log_output_path -j oe $send_email_script"
chmod 660 $log_output_path

disseminate=`grep $PROJECT_TAG $RUN_DIR_BCL2FASTQ/*.discard | cut -d "," -f10 | sort | uniq | wc -l`
if [ "$disseminate" -eq 0 ]; then
        echo "SEND_EMAIL"
else
        # Prepare and send email with reads under the threshold
        discard_mail=discard_mail_$SEQ_RUN_NAME.$PROJECT_TAG
        cp $MAIL_TEMPLATE_PATH/discard_mail.tml $RUN_DIR_BCL2FASTQ/$discard_mail
        echo "SEQUENCE RUN NAME $SEQ_RUN_NAME" >>  $RUN_DIR_BCL2FASTQ/$discard_mail
        echo "PROJECT NAME  $PROJECT_TAG" >>  $RUN_DIR_BCL2FASTQ/$discard_mail
        `grep $PROJECT_TAG $RUN_DIR_BCL2FASTQ/*.discard >> $RUN_DIR_BCL2FASTQ/$discard_mail`
        sendmail -t < $RUN_DIR_BCL2FASTQ/$discard_mail
        echo "NO SEND_EMAIL"
fi

