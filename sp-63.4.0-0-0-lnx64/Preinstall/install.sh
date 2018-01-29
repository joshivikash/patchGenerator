#!/bin/bash

source /etc/profile

rm -rf /opt/cisco/ss/adminshell/properties/asd.properties
cp -f asd.properties /opt/cisco/ss/adminshell/properties
chmod 644 /opt/cisco/ss/adminshell/properties/asd.properties

echo "NCCM 3.4" > /opt/LCM/info/build.txt

exit 0
