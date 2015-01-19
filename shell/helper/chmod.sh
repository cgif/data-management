INPUT_DIR=$1

for FILE in `find $INPUT_DIR -name "*"`
do

	#check if file is a directory (-d), file (-f) or symbolic link (-h)
	#
	if [[ -d "$FILE" ]]
	then 
		PERMISSIONS=770
		#echo $PERMISSIONS
		chmod $PERMISSIONS $FILE
	elif [[ -f "$FILE" ]]
	then 
		PERMISSIONS=660
		#echo $PERMISSIONS
		chmod $PERMISSIONS $FILE
	elif [[ -h "$FILE" ]]
	then
		echo -n ""
	fi
	
done;
