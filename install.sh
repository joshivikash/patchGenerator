#!/bin/bash

unzip ServerPatch
# Copying the files from ServerPatch.zip to /var/pari/dash
for file in `unzip -Z -1 ServerPatch`; do
	\cp -f $line \var\pari\dash
done
# Executing commands from 'instructions' file
bash instructions.txt
