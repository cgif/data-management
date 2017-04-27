#!/bin/bash
#
# script to run send_email 
#

#PBS -l walltime=72:00:00
#PBS -l select=1:ncpus=1:mem=1024kb

#PBS -m ea
#PBS -M igf@imperial.ac.uk
#PBS -j oe

#PBS -q pqcgi


#now
NOW="date +%Y-%m-%d%t%T%t"

#today
TODAY=`date +%Y-%m-%d`
CUSTOMER_EMAIL=#customerEmail
CUSTOMER_USERNAME=#customerUsername
IRODS_USER=igf
IRODS_PWD=igf

sendmail -t < $CUSTOMER_EMAIL
