#!/usr/bin/env bash

clear

echo "-- Get TPL files"
curl -LO https://github.com/msadig/django-starter/archive/master.zip > master.zip
unzip master.zip
rm master.zip
cd ./django-starter-master


echo "Create configuration? (y/n)"
read -e run
if [ "$run" == n ] ; then
	echo "Path of the existing config file: "
	read -e confpath
	sed -i.bak -e 's|#{CONFIGPATH}|'$confpath'|g' script/app.sh
	sed -i.bak -e 's|#{CONFIGPATH}|'$confpath'|g' script/destroy.sh
	rm -rfv script/*.bak
exit
else
	rm -rfv config.txt
	echo "=> Site URL or IP: "
	read -e server
	echo "=> App's Server User: "
	read -e appuser
	echo "=> App Name: "
	read -e appname
	echo "=> Path to app: "
	read -e apppath
	echo "=> Database User: "
	read -e db_user
	echo "=> Database User's password: "
	read -e db_password
	echo "=> Database Name: "
	read -e db_name

	sed 's|#{server}|'$server'|g' tpl/conf.bak > config.txt
	sed -i.bak -e 's|#{appuser}|'$appuser'|g' -e 's|#{appname}|'$appname'|g' -e 's|#{apppath}|'$apppath'|g' -e 's|#{db_user}|'$db_user'|g' -e 's|#{db_password}|'$db_password'|g' -e 's|#{db_name}|'$db_name'|g' config.txt
	rm config.txt.bak
fi
exit 0
