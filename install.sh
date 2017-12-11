#!/bin/bash

rm -R -f linux_release
unzip ServerPatch
# Copying the files from ServerPatch.zip to /var/pari/dash
for file in `unzip -Z -1 ServerPatch`; do
        file="$(echo $line | sed 's#\\#\/#g#')"
        newLine="$(echo $line | cut -c 15-)"
# If the file is a properties or xml file, and if it exists in both places, then merge them
	\cp -f $line '/var/pari/dash/'$newLine
done
# Executing commands from 'instructions' file
bash instructions.txt
