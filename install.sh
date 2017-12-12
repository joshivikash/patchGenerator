#!/bin/bash

rm -R -f linux_release
unzip ServerPatch
# Copying the files from ServerPatch.zip to /var/pari/dash
for file in `unzip -Z -1 ServerPatch`; do
        file="$(echo $file | sed 's#\\#\/#g#')"
        newFile="$(echo $file | cut -c 15-)"
		
	# If the file is a properties or xml file, and if it exists in both places, then merge them
	catCommandResult=$( cat '/var/pari/dash/'$newFile)
	isFileAlreadyExist=""
	if [[ $catCommandResult == *'No such file or directory' ]]
		then
			isFileAlreadyExist='fileAbsent'
		else
			isFileAlreadyExist='filePresent'
	fi
	
	if [[ $isFileAlreadyExist == 'filePresent' ]]
		then
			if [i gt 0]
				then
					if [[ $file == *".xml" || $file == *".properties" ]]
						then
							if [$file == *".xml"]
								then
										echo "TODO: XML Merging"
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
	fi
		
	\cp -f $file '/var/pari/dash/'$newFile
done
# Executing commands from 'instructions' file
bash instructions.txt
