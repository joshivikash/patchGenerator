#!/bin/bash

source /etc/profile

rm -rf /opt/cisco/ss/adminshell/properties/asd.properties
cp -f asd.properties /opt/cisco/ss/adminshell/properties
chmod 644 /opt/cisco/ss/adminshell/properties/asd.properties

sed -i -e 's/61616/61617/g' /opt/ConcsoTgw/tail-end-gateway-decoupled/conf/tail-end-gateway-spring.xml
/etc/init.d/concsotgw restart

sed -i -e 's/nccm.inbound.queue/collector.inbound.queue/g' /opt/cisco/ss/adminshell/properties/tail-end-gateway.properties

echo "Stopping NCCM Service..."
service dash stop

exit 0
