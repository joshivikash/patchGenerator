#!/bin/bash

rm -R -f linux_release
unzip ServerPatch
# Copying the files from ServerPatch.zip to /var/pari/dash
for line in `unzip -Z -1 ServerPatch`; do
        line="$(echo $line | sed 's#\\#\/#g#')"
        newLine="$(echo $line | cut -c 15-)"
	\cp -f $line '/var/pari/dash/'$newLine
done
# Executing commands from 'instructions' file
bash instructions.txt
