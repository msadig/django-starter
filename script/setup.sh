#!/usr/bin/env bash

clear

echo "-- Get TPL files"
curl -LO https://github.com/msadig/django-starter/archive/master.tar.gz > master.tar.gz
gzip -dc master.tar.gz | tar xvf -
rm master.tar.gz
mv ./django-starter-master ./django-starter && cd ./django-starter


echo "Create configuration file? (y/n)"
read -e run
if [ "$run" == n ] ; then
	echo "Process complated, now you can define your app parameters from ./django-starter/config.txt and then run 'bash ./django-starter/script/app.sh'"
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

	echo "Process complated, now run the 'bash ./django-starter/script/app.sh' command for the creating Django app with the paremeters you've defined."
fi
exit 0