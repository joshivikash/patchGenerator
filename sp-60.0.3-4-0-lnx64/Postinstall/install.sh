#!/bin/bash
source /etc/profile
export PATH=/opt/java/jre/bin:$PATH

SCRIPT_DIR="/opt/LCM/bin"

/bin/sed -i '/iptables/d' /etc/rc.local
/bin/sed -i '/temp_script/d' /etc/rc.local
/bin/sed -i '/iptables/d' /etc/rc.d/rc.local
/bin/sed -i '/temp_script/d' /etc/rc.d/rc.local

echo "Running postinstall"

/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'Rules Pack';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'NOS Rules';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'NOS Configurer';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'NCCM Add-on';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'Data Pack';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name LIKE '%Audit%';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'CSPC SE Add-on';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'CSPC IMS Rules';"
/bin/sh /opt/LCM/bin/sqliteToDerbyScripts_shell.sh "connect 'jdbc:derby://localhost:1527/opt/LCM/info/status;create=true;user=app;password=password';" "delete from status where name = 'CSPC IMS Add-on';"

chmod 644 /opt/LCM/info/build.txt

/bin/cp -f cspc_firewall /opt/
/bin/cp -f cspc_ipv6firewall /opt/
/bin/cp -f modify_iptables.sh /opt/
/bin/chmod 755 /opt/modify_iptables.sh

echo "#One time change for iptable issue">>/etc/rc.local
echo "cd /opt/">>/etc/rc.local
echo "./modify_iptables.sh >> /opt/LCM/logs/install" >>/etc/rc.local

echo "#One time change for iptable issue">>/etc/rc.d/rc.local
echo "cd /opt/">>/etc/rc.d/rc.local
echo "./modify_iptables.sh >> /opt/LCM/logs/install" >>/etc/rc.d/rc.local


/sbin/restorecon -Rv / >/dev/null 2>&1

yes | cp -f /opt/backup/proxyconfig.properties $CSPCHOME/resources/kernel/tg
yes | cp -f /opt/backup/scproxyinfo /etc/
#CSCvf49220

/bin/rm -rf /opt/backup
: <<'END'
CRON_JOB_STATUS=$(/usr/bin/crontab -ls | grep reboot | wc -l)
if [[ ( ! ( -e /tmp/req_reboot.sh ) ) || ( $CRON_JOB_STATUS != "1" ) ]] ; then
sed -i "/req_reboot.sh/d" /home/collectorlogin/.bash_profile
sed -i "/req_reboot.sh/d" /root/.bash_profile
sed -i "/req_reboot.sh/d" /opt/cisco/ss/adminshell/bin/banner.sh
cp -f req_reboot.sh /tmp/
cp -f reboot /tmp/
/bin/chmod 755 /tmp/req_reboot.sh
/bin/chmod 755 /tmp/reboot
echo "@reboot /tmp/reboot">cronjob
/usr/bin/crontab cronjob
/usr/bin/crontab -l
echo "/tmp/req_reboot.sh">>/home/collectorlogin/.bash_profile
echo "/tmp/req_reboot.sh">>/root/.bash_profile
/bin/rm -f cronjob
else
echo "System already requires a reboot"
fi
END

#CSCve49250
touch /opt/ConcsoTgw/tail-end-gateway-decoupled/resetwebsocket
chmod 777 /opt/ConcsoTgw/tail-end-gateway-decoupled/resetwebsocket

unzip -o LCM_DERBY_Scripts.zip -d $SCRIPT_DIR

chmod 755 $SCRIPT_DIR/*.exp
chmod 755 $SCRIPT_DIR/*.tcl
chmod 755 $SCRIPT_DIR/*.sh
chmod 644 $SCRIPT_DIR/*.jar

rm -rf /opt/LCM/info/*.db

echo "Starting NCCM Service..."
service dash start

if [[ -e /tmp/initial_configuration ]] ; then

echo "Fresh Installation..Skipping Reboot"
else
echo "============================"
echo "Rebooting the appliance now"
echo "============================"
/sbin/shutdown -P +1 -r now &
fi

exit 0


