#!/bin/bash

rm -R -f linux_release
# Creating backup folder
timestamp=$( date +%s )
bk_dir="/var/pari/dash_bk_"$timestamp
mkdir $bk_dir

unzip ServerPatch
# Copying the files from ServerPatch.zip to /var/pari/dash
for file in `unzip -Z -1 ServerPatch`; do
        file="$(echo $file | sed 's#\\#\/#g#')"
        newFile="$(echo $file | cut -c 15-)"
		
	# If the file exists in both places
	lsCommandResult=$( ls '/var/pari/dash/'$newFile)
	isFileAlreadyExist=""
	if [[ $lsCommandResult == *'No such file or directory' ]]
		then
			isFileAlreadyExist='fileAbsent'
		else
			isFileAlreadyExist='filePresent'
	fi
	
	if [[ $isFileAlreadyExist == 'filePresent' ]]
		then
			# Take a back up of that file
				# Step:1) Create required parent folder under backup folder
					# Step:1:i) Extract the directory structure of the file to be backed up
						# Step:1:i:a) Calculating the last index of the "/" in the file name
							rev_bk_file=$( echo $newFile | rev ) # Reversing the name of the file
							indx=`expr index $rev_bk_file /`
					dir=$( echo ${rev_bk_file:indx} | rev )
				mkdir -p $bk_dir/$dir
				
				# Step:2) Take the backup
				cp '/var/pari/dash/'$newFile $bk_dir/$newFile
				
				# Step:3) Reset the owner and group of the backed up file
				owner=$( ls -l /var/pari/dash/$newFile | awk '{print $3}' )
				group=$( ls -l /var/pari/dash/$newFile | awk '{print $4}' )
				chown $owner:$group $bk_dir/$newFile
			
			# If the file is a "properties" or "xml" file, then merge them
			if [[ $file == *".xml" || $file == *".properties" ]]
						then
							if [$file == *".xml"]
								then
										/var/pari/dash/jre/java -classpath nccmInstallUtil.jar com.pari.pwd.util.XMLMerger $file $newFile
							elif [[ $newFile == "resources/server/global/nccmDatabase.properties" ]]
								then
									 awk -F= '!a[$1]++' /var/pari/dash/resources/server/global/nccmDatabase.properties $file > /var/pari/dash/resources/server/global/nccmDBPropMerge
									 
									 mv /var/pari/dash/resources/server/global/nccmDBPropMerge /var/pari/dash/resources/server/global/nccmDatabase.properties
									 
									 chmod 755 /var/pari/dash/resources/server/global/nccmDatabase.properties
									 
							elif [[ $newFile == "resources/server/global/nccm.properties" ]]
								then
									 awk -F= '!a[$1]++' /var/pari/dash/resources/server/global/nccm.properties $file > /var/pari/dash/resources/server/global/nccmPropMerge
									 
									 mv /var/pari/dash/resources/server/global/nccmPropMerge /var/pari/dash/resources/server/global/nccm.properties
									 
									 chmod 755 /var/pari/dash/resources/server/global/nccm.properties
									 
							elif [[ $newFile == "resources/server/global/cma.properties" ]]
								then
									 awk -F= '!a[$1]++' /var/pari/dash/resources/server/global/cma.properties $file > /var/pari/dash/resources/server/global/cmaPropMerge
									 
									 mv /var/pari/dash/resources/server/global/cmaPropMerge /var/pari/dash/resources/server/global/cma.properties
									 
									 chmod 755 /var/pari/dash/resources/server/global/cma.properties
									 
							elif [[ $newFile == "resources/server/global/nccm-asd.properties" ]]
								then
									 awk -F= '!a[$1]++' /var/pari/dash/resources/server/global/nccm-asd.properties $file > /var/pari/dash/resources/server/global/asdPropMerge
									 
									 mv /var/pari/dash/resources/server/global/asdPropMerge /var/pari/dash/resources/server/global/nccm-asd.properties
					fi
	fi
		
	\cp -f $file '/var/pari/dash/'$newFile
done
# Executing commands from 'instructions' file
bash instructions.txt
