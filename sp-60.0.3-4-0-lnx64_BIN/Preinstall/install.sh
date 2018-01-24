#!/bin/bash

source /etc/profile

rm -rf /opt/cisco/ss/adminshell/properties/asd.properties
cp -f asd.properties /opt/cisco/ss/adminshell/properties
chmod 644 /opt/cisco/ss/adminshell/properties/asd.properties

sed -i -e 's/nccm.inbound.queue/collector.inbound.queue/g' /opt/cisco/ss/adminshell/properties/tail-end-gateway.properties
sed -i -e 's/nccm.outbound.queue/collector.outbound.queue/g' /opt/cisco/ss/adminshell/properties/tail-end-gateway.properties
echo "NCCM 3.4" > /opt/LCM/info/build.txt

exit 0
