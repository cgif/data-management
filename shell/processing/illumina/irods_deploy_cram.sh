#!/bin/bash

#
# script to store cram files in irods, on the eliot Vault (eliotResc)
#
#

#PBS -l walltime=5:00:00
#PBS -l select=1:ncpus=1:mem=1024mb:tmpspace=15


#PBS -m ea
#PBS -M mkanwagi@imperial.ac.uk
#PBS -j oe

#PBS -q pqcgi


NOW=2014-11-19
PATH_OUTPUT_CRAM=#cram_output_path
DATA_VOL_IGF=/project/tgu


RUN_NAME=`echo $PATH_OUTPUT_CRAM | cut -f8 -d/ | awk 'BEGIN{FS="_"}{print $1"_"$2"_"$3"_"$4}'`	
FLOWCELL_ID=`echo $RUN_NAME | cut -f4 -d '_' | perl -e '$flowcell_id=<>; $flowcell_id=substr($flowcell_id,1,9); print "$flowcell_id\n"'`
SAMPLESHEET_PATH=$DATA_VOL_IGF/rawdata/seqrun/bcl/$RUN_NAME/$FLOWCELL_ID.csv


#ADDING CRAM FILES TO ELIOT(eliotResc)
module load irods
iinit mmuelle1



project_name=`echo $PATH_OUTPUT_CRAM | cut -f5 -d/`
sample_name=`echo $PATH_OUTPUT_CRAM | cut -f7 -d/`
cram_name=`echo $PATH_OUTPUT_CRAM | cut -f8 -d/`




#this checks if the user was already created in irods, by looking for their name
echo "$NOW checking if user has been created..." 
user=`iadmin lu | grep $project_name.user | awk -v user_name=$project_name.user 'BEGIN{FS="#"}{if ($1 == user_name) {print$1}}'`

#if the user has not yet been created, then we create them
if [ "$user" = "" ]
then 
	echo "$NOW creating user ..." 
	#make user
	iadmin mkuser $project_name.user#igfZone rodsuser

	#generate a passwd
	USER_PASSWORD=`openssl rand -base64 8`
	iadmin moduser $project_name.user#igfZone password $USER_PASSWORD
	
	ichmod -rM own mmuelle1 /igfZone/home/$project_name.user
	ichmod -rM inherit /igfZone/home/$project_name.user
	

	#send email to the user 
	#EMAIL-CONTACT=
	ssh eliot.med.ic.ac.uk "echo -e \"Hi there, \n This is an email from the Imperial Genomics Facility.\n Please go to; http://eliot.med.ic.ac.uk:8080/idrop-web2/browse/index#absPath=/igfZone/home/igf/$project_name.user&browseOptionVal=info , then click on the 'Browse' tab to view/download your data.\n\n Use the credentials below to log-in: \n username: $project_name.user \n password: $USER_PASSWORD \n\n Thank you.\" | mail -s \"Voila...Your Data from Sequencing run $RUN_NAME is available for download\"  igf@imperial.ac.uk -c mmuelle1@imperial.ac.uk"

fi



#creating sample directories in the user's irods home_directory
echo "$NOW creating sample directories..." 
cram_dir_irods=/igfZone/home/$project_name.user/rawdata/$sample_name
imkdir -p $cram_dir_irods
										#in the consequent lines, irods user mmuelle1 is going to operate on another user's collection(project_name),
ichmod -rM read $project_name.user $cram_dir_irods				#   to be able to do this, mmuelle1 had to be given 'own' rights on this collection - check CGI-wiki page on how to do this
										#Also, mmuelle1 removes all other permissions from the user 'project_name', apart from read permissions   
echo "$NOW storing sample cram files in irods..." 
iput -fP -R eliotResc $PATH_OUTPUT_CRAM $cram_dir_irods/$cram_name
										

#ADDING meta-data TO CRAM FILES ON ELIOT

#obtaining the meta-data values
echo "$NOW starting to attach meta-data to the sample cram files; obtaining the meta-data values..." 

species=`awk -v sample=$sample_name 'BEGIN {FS=","} {if($3 == sample) {print $11}}' $SAMPLESHEET_PATH`
assembly=`awk -v sample=$sample_name 'BEGIN {FS=","} {if($3 == sample) {print $12}}' $SAMPLESHEET_PATH`
seq_type=`awk -v sample=$sample_name 'BEGIN {FS=","} {if($3 == sample) {print $13}}' $SAMPLESHEET_PATH`

#sequencing_date=`ssh wcma-mmuelle1-s1.hh.med.ic.ac.uk "cat $ORWELL_SEQRUNS_DIR/$RUN_NAME/RTAComplete.txt | cut -f1 -d,"`	#should be this line
sequencing_date=`ssh eliot.med.ic.ac.uk "cat /home/mkanwagi/RTAComplete.txt | cut -f1 -d,"`	#used this for testing
conversion_date=`date +%m/%d/%Y`
			
#adding the meta-data
echo "$NOW attaching meta-data to the sample cram files..." 

imeta add -d $cram_dir_irods/$cram_name species $species
imeta add -d $cram_dir_irods/$cram_name assembly $assembly
imeta add -d $cram_dir_irods/$cram_name sequence_type $seq_type
imeta add -d $cram_dir_irods/$cram_name sequencing_date $sequencing_date
imeta add -d $cram_dir_irods/$cram_name conversion_date $conversion_date

echo "$NOW Done with deploying sample cram files on irods :)"




