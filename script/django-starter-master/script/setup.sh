#!/usr/bin/env bash

clear

echo "config path: "

read -e confpath

. $confpath

echo $DJANGO_PATH

curl -LO https://github.com/msadig/django-starter/archive/master.zip > master.zip
unzip master.zip
rm master.zip

cd django-starter-master
sed -i -e 's|#{CONFIGPATH}|'$confpath'|g' app.sh
sed -i -e 's|#{CONFIGPATH}|'$confpath'|g' destroy.sh
