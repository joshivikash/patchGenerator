#!/bin/bash

# Init
INSTALL_SCRIPT_DIR="`dirname \"$0\"`"
INSTALL_SCRIPT_DIR="`( cd \"$INSTALL_SCRIPT_DIR\" && pwd )`"
echo $INSTALL_SCRIPT_DIR 
USER_INSTALL_FOLDER_1=/var/pari
USER_INSTALL_FOLDER_2=/var/pari/dash
SP_APPLY_TIMESTAMP=$( date +%s )
rm -rf $USER_INSTALL_FOLDER_1/dash_backup
mkdir $USER_INSTALL_FOLDER_1/dash_backup
cp -a $USER_INSTALL_FOLDER_2/. $USER_INSTALL_FOLDER_1/dash_backup
rm -rf $USER_INSTALL_FOLDER_2/SP_TEMP*
mkdir $USER_INSTALL_FOLDER_2/SP_TEMP_$SP_APPLY_TIMESTAMP
USER_INSTALL_DIR=$USER_INSTALL_FOLDER_2/SP_TEMP_$SP_APPLY_TIMESTAMP
chmod -R 777 $USER_INSTALL_FOLDER_2/
echo "Stopping NCCM server....."
service dash stop
echo "NCCM Server Stopped"
bash $INSTALL_SCRIPT_DIR/instructions.txt


# Installing
export NCCMHOME=$USER_INSTALL_FOLDER_2
export JRE_HOME=$USER_INSTALL_FOLDER_2/jre
export PATH=$PATH:$USER_INSTALL_FOLDER_2/jre/bin/
cp ServerPatch.zip  $USER_INSTALL_DIR/ServerPatch.zip
cd $USER_INSTALL_DIR
unzip ServerPatch
rm -f ServerPatch.zip
unzip PerlModules
rm -f PerlModules.zip
chmod +x *.sh
chmod +x *.sql
chmod +x dash

#Post Install
if [ -f $USER_INSTALL_DIR/dash ]
	then
	    echo "Overwriting dash..."
        \cp -f $USER_INSTALL_DIR/dash /etc/init.d/
		dos2unix /etc/init.d/dash
fi
if [ -f /etc/init.d/dash ]
	then
	    echo "dash file present"
fi
if [ -f $USER_INSTALL_DIR/catalinaLogRotation ]
	then
		echo "Overwriting catalinaLogRotation..."
        \cp -f $USER_INSTALL_DIR/catalinaLogRotation  /etc/logrotate.d/
		dos2unix /etc/logrotate.d/catalinaLogRotation
fi
if [ -f /etc/logrotate.d/catalinaLogRotation ]
	then
		echo "catalinaLogRotation is present"
fi
sh $USER_INSTALL_DIR/nccm_misc.sh
chmod 777 $USER_INSTALL_DIR/linux_release/*
chmod +x $USER_INSTALL_DIR/linux_release/webui/tomcat/bin/*.sh
chmod 777 $USER_INSTALL_DIR/linux_release/webui/tomcat/webapps/*
\cp -rf $USER_INSTALL_DIR/linux_release/. $USER_INSTALL_FOLDER_2
rm -rf $USER_INSTALL_DIR/linux_release
\cp -rf $USER_INSTALL_DIR/. $USER_INSTALL_FOLDER_2/bin
dos2unix $USER_INSTALL_FOLDER_2/bin/*.sh
dos2unix $USER_INSTALL_FOLDER_2/bin/*.sql
dos2unix $USER_INSTALL_FOLDER_2/bin/*.tcl
dos2unix $USER_INSTALL_FOLDER_2/bin/catalinaLogRotation
dos2unix $USER_INSTALL_FOLDER_2/bin/dash
sh $USER_INSTALL_FOLDER_2/bin/upgrade_properties.sh
rm -rf $USER_INSTALL_DIR
cd 
chmod -R 777 $USER_INSTALL_FOLDER_2/
sh $USER_INSTALL_FOLDER_2/bin/postInstall.sh
sh $USER_INSTALL_FOLDER_2/bin/PerlModules/installPerlModules.sh
sh $USER_INSTALL_FOLDER_2/bin/certificate_check.sh
sh $USER_INSTALL_FOLDER_2/bin/RHELScriptExecutor.sh
sh $USER_INSTALL_FOLDER_2/bin/upgradedb.sh 1
sh $USER_INSTALL_FOLDER_2/bin/upgradewebuserdb.sh
sleep 15s
chmod -R 775 $USER_INSTALL_FOLDER_2/
chown -R nccmuser:nccmusers  $USER_INSTALL_FOLDER_2/logs
chown -R nccmuser:nccmusers $USER_INSTALL_FOLDER_2/webui
chown -R nccmuser:nccmusers $USER_INSTALL_FOLDER_1/startup.log
chown -R nccmuser:nccmusers  $USER_INSTALL_FOLDER_2/tomcat.out
chown -R nccmuser:nccmusers $USER_INSTALL_FOLDER_2/logs/nccmws.log
chmod -R 750 $USER_INSTALL_FOLDER_2/logs
chmod 744 $USER_INSTALL_FOLDER_2/resources/server/pasrule/osVersions.xml
chmod 777 $USER_INSTALL_FOLDER_2/tmp
setfacl -Rm d:u::rwx,d:g::rx $USER_INSTALL_FOLDER_2/logs
# Extracting new web.xml from nccmweb.war for Password Updation
cd $USER_INSTALL_FOLDER_2/webui/tomcat/webapps
rm -rf nccmweb
mkdir WEB-INF
touch WEB-INF/web.xml
unzip -p nccmweb.war WEB-INF/web.xml > WEB-INF/web.xml

# Getting the old password from old web.xml and replacing in new web.xml
NEW_WEBXML_PATH=dash/webui/tomcat/webapps/WEB-INF/web.xml
OLD_WEBXML_PATH=dash_backup/webui/tomcat/webapps/nccmweb/WEB-INF/web.xml
pwdLineInNewWebXml="$(grep -n config.nccmserver.systemuser_pwd $USER_INSTALL_FOLDER_1/$NEW_WEBXML_PATH | sed -r 's#([0-9][0-9]*).*#\1#')"
pwdLineInNewWebXml=`expr $pwdLineInNewWebXml + 1`
newPwd=$(sed -n $pwdLineInNewWebXml'p' $USER_INSTALL_FOLDER_1/$NEW_WEBXML_PATH | sed -r 's#^[ /t]*##' | sed -r 's#[ /t]*$##' | sed 's#<param-value>##' | sed 's#</param-value>##')
newPwd=$(echo $newPwd | sed 's/[[:space:]]//g')
pwdLineInOldWebXml="$(grep -n config.nccmserver.systemuser_pwd $USER_INSTALL_FOLDER_1/$OLD_WEBXML_PATH | sed -r 's#([0-9][0-9]*).*#\1#')"
pwdLineInOldWebXml=`expr $pwdLineInOldWebXml + 1`
oldPwd=$(sed -n $pwdLineInOldWebXml'p' $USER_INSTALL_FOLDER_1/$OLD_WEBXML_PATH | sed -r 's#^[ /t]*##' | sed -r 's#[ /t]*$##' | sed 's#<param-value>##' | sed 's#</param-value>##')
oldPwd=$(echo $oldPwd | sed 's/[[:space:]]//g')
sed -i "s/$newPwd/$oldPwd/" $USER_INSTALL_FOLDER_1/$NEW_WEBXML_PATH

# Updating nccmweb.war with the updated new web.xml
zip nccmweb.war WEB-INF/web.xml
rm -rf WEB-INF/
cd -

echo "starting NCCM Server"
service dash start
echo "NCCM Server Started"
if [ -d $USER_INSTALL_FOLDER_2/resources/server/serverhm/ ]
        then
                cd $USER_INSTALL_FOLDER_2/resources/server/serverhm/
                sh $USER_INSTALL_FOLDER_2/resources/server/serverhm/syshealth_installer.sh
                rm -rf $USER_INSTALL_FOLDER_2/resources/server/serverhm/
                chmod -R 775 $USER_INSTALL_FOLDER_2/serverhm/syshealth/bin/
                /usr/bin/tclsh $USER_INSTALL_FOLDER_2/serverhm/syshealth/system/nccm_commands_executer.tcl 2>/tmp/out.err 1>/tmp/out.log
fi
