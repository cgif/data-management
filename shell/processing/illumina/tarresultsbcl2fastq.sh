#!/bin/bash
#
# script to run tarBcl2FastqResults 
#

# PBS -l walltime=#walltimeHours:00:00
# PBS -l select=1:ncpus=#threads:mem=1024mb:tmpspace=#tmpSpacegb

#PBS -m ea
#PBS -M cgi@imperial.ac.uk
#PBS -j oe

# PBS -q #queue


#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`

#set up script
PATH_PROJECT_TAG_DIR=#pathProjectTagDir
SEQ_RUN_DATE=#seqRunDate
SEQ_RUN_NAME=#seqRunName
RUN_DIR_BCL2FASTQ=#runDirBcl2Fastq
CUSTOMER_FILE_PATH=#customerFilePath
PROJECT_TAG=#projectTag
MAIL_TEMPLATE_PATH=#mailTemplatePath
PATH_TO_DESTINATION=#pathToDestination
DEPLOYMENT_SERVER=#deploymentServer
DEPLOYMENT_TAR_BASE_DIR=#deploymentTarPath
DEPLOYMENT_SYMBOLIC_LINK=#deploymentSymbolicLink

echo "`$NOW` tarring the archive of $SEQ_RUN_DATE ..."
ssh login.cx1.hpc.ic.ac.uk "tar cfz $PATH_TO_DESTINATION/$SEQ_RUN_DATE.tar.gz  $PATH_PROJECT_TAG_DIR/$SEQ_RUN_DATE"	

echo "`$NOW` tar of $SEQ_RUN_DATE completed"

#generate an md5 checksum for the tarball
#need to change to location of archive to generate md5
echo "`$NOW` Generating md5 checksum for TAR archive..."
ssh login.cx1.hpc.ic.ac.uk "cd $PATH_TO_DESTINATION; md5sum $SEQ_RUN_DATE.tar.gz > $SEQ_RUN_DATE.tar.gz.md5; chmod 664 $SEQ_RUN_DATE.tar.gz $SEQ_RUN_DATE.tar.gz.md5"
echo "`$NOW` md5 checksum Generated"

#change to location where the tar and the md5 file are & check 
MD5_STATUS=`ssh login.cx1.hpc.ic.ac.uk "cd $PATH_TO_DESTINATION; md5sum -c $SEQ_RUN_DATE.tar.gz.md5 2>&1 | head -n 1 | cut -f 2 -d ' '"`
echo  $MD5_STATUS

#abort if md5 check fails
if [[ $MD5_STATUS == 'FAILED' ]]
then
        #send email alert...
        echo -e "subject:Sequencing Run $SEQ_RUN_NAME TAR Processing Error - MD5 check failed\nThe MD5 check for the file transfer of sequencing run $SEQ_RUN_NAME failed. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "mmuelle1@ic.ac.uk"

        #...and exit
        exit 1
fi

# creates rnd name for result directory
rnddir_results=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w ${1:-15} | head -n 1` 
PATH_TO_RNDDIR=$DEPLOYMENT_TAR_BASE_DIR/$rnddir_results
ssh $DEPLOYMENT_SERVER "mkdir -m 775 -p $PATH_TO_RNDDIR" 

echo "`$NOW` coping TAR archive on eliot server ..."
scp -r $PATH_TO_DESTINATION/$SEQ_RUN_DATE.tar.gz* $DEPLOYMENT_SERVER:$PATH_TO_RNDDIR 
#create project_tag dir & symbolic link
ssh $DEPLOYMENT_SERVER "mkdir -m 770 -p $DEPLOYMENT_SYMBOLIC_LINK"
ssh $DEPLOYMENT_SERVER "ln -s  $PATH_TO_RNDDIR $DEPLOYMENT_SYMBOLIC_LINK/fastq"

#change to location where the tar and the md5 file are & check
MD5_STATUS=`ssh $DEPLOYMENT_SERVER "cd $PATH_TO_RNDDIR; md5sum -c $SEQ_RUN_DATE.tar.gz.md5 2>&1 | head -n 1 | cut -f 2 -d ' '"`
echo  $MD5_STATUS

#abort if md5 check fails
if [[ $MD5_STATUS == 'FAILED' ]]
then
        #send email alert...
        echo -e "subject:Sequencing Run $SEQ_RUN_NAME Deploying Error - MD5 check failed\nThe MD5 check for the file transfer of sequencing run $SEQ_RUN_NAME failed. Processing aborted." | sendmail -f igf -F "Imperial BRC Genomics Facility" "mmuelle1@ic.ac.uk"

        #...and exit
        exit 1
fi

#now remove the tar file
echo "`$NOW` remove tar from eliot server ..."
ssh login.cx1.hpc.ic.ac.uk "rm $PATH_TO_DESTINATION/$SEQ_RUN_DATE.tar.gz*" 
echo "`$NOW` Files have been deployed, Well done!"

#now send mail to the customer
customers_info=`grep -w $PROJECT_TAG $CUSTOMER_FILE_PATH/customerInfo.csv`
customer_name=`echo $customers_info|cut -d ',' -f2`
customer_username=`echo $customers_info|cut -d ',' -f3`
customer_passwd=`echo $customers_info|cut -d ',' -f4`
customer_email=`echo $customers_info|cut -d ',' -f5`
#for TEST
#echo "value customer #$customer_email#"
if [[ $customer_email != *"@"* ]]; then
	#send email alert...
	#echo -e "subject:Sequencing Run $SEQ_RUN_NAME Deploying Warning - the email address for $customer_username is unknown." | sendmail -f igf -F "Imperial BRC Genomics Facility" "mmuelle1@ic.ac.uk"
	echo -e "subject:Sequencing Run $SEQ_RUN_NAME Deploying Warning - the email address for $customer_username is unknown." | sendmail -f igf -F "Imperial BRC Genomics Facility" "mmuelle1@ic.ac.uk"
fi
customer_mail=customer_mail.$PROJECT_TAG
cp $MAIL_TEMPLATE_PATH/customer_mail.tml $RUN_DIR_BCL2FASTQ/$customer_mail
chmod 770 $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#customerEmail/$customer_email/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#customerName/$customer_name/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#customerUsername/$customer_username/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#passwd/$customer_passwd/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#projectName/$PROJECT_TAG/" $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i -e "s/#projectRunDate/$SEQ_RUN_DATE/" $RUN_DIR_BCL2FASTQ/$customer_mail
sendmail -t < $RUN_DIR_BCL2FASTQ/$customer_mail 
#now remove 
rm $RUN_DIR_BCL2FASTQ/$customer_mail
sed -i /$PROJECT_TAG/d $CUSTOMER_FILE_PATH/customerInfo.csv
