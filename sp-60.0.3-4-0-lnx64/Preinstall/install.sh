#!/bin/bash

source /etc/profile

rm -rf /opt/cisco/ss/adminshell/properties/asd.properties
cp -f asd.properties /opt/cisco/ss/adminshell/properties
chmod 644 /opt/cisco/ss/adminshell/properties/asd.properties

echo "Stopping NCCM Service..."
service dash stop

exit 0
