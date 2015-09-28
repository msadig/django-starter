#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# GET APP VARIABLES FROM CONFIG
script_dir="$(dirname "$0")"
. $script_dir/../config.txt



# login as root
#sudo su
echo "Starting Provision as `whoami`"

echo "----- Provision: System Update & Upgrade..."
sudo aptitude -y update
sudo aptitude -y upgrade

# Development tools
echo "----- Provision: Installing SUDO Requirements..."
sudo aptitude install -y postgresql postgresql-contrib libpq-dev python-dev supervisor nginx git python3-pip

# Note: in the new version of the Ubuntu pyvenv not preinstalled
if ! pyvenv_3="$(type -p pyvenv-3.4)" || [ -z "$pyvenv_3" ]; then
  # install foobar here
  sudo apt-get install python3.4-venv # http://askubuntu.com/a/528625, http://stackoverflow.com/a/7522866/968751
fi



# Create user, group and assign home directory IF not exists
if ! id -u $APP_USER > /dev/null 2>&1; then
	echo "----- Provision: Create APP User and assign home directory..."
	if ! grep -q $APP_USER_GROUP /etc/group;
	then
	   sudo groupadd --system $APP_USER_GROUP
	fi
	randompw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1) #random password
	sudo useradd --system --gid $APP_USER_GROUP --shell /bin/bash --home $APP_PATH $APP_USER
	
	# Assign the password to the user.
	# Password is passed via stdin, *twice* (for confirmation).
	sudo passwd $APP_USER <<< "$randompw"$'\n'"$randompw"
	echo "=============================================================================="
	echo "******************************************************************************"
	echo " "
	echo "User:" $APP_USER "has been created with the following password:" $randompw
	echo " "
	echo "******************************************************************************"
	echo "=============================================================================="


fi


# Create apps user and assign app directory to him
sudo mkdir -p $APP_PATH
sudo chown $APP_USER $APP_PATH

# Give write permission to app user
sudo chown -R $APP_USER:users $APP_PATH
sudo chmod -R g+w $APP_PATH
sudo usermod -a -G users `whoami`




# ------------------------------------------------------------------------------
# Database creation
echo "----- PostgreSQL: Creating database and user..."
sudo su - postgres << EOF
# -------[script begins]-------

# psql --help
psql -c "
CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASSWORD';
"
createdb --owner $APP_DB_USER $APP_DB_NAME


# -------[script ends]-------
EOF


# ------------------------------------------------------------------------------
# If wants create existing project
read -p "Do you wish to create existing project? (y/n): " prj_exists
if [ "$prj_exists" == y ] ; then
read -p "Please prvide URL for the GIT repository: " git_repo
fi

# ------------------------------------------------------------------------------
# RUN SCRIPTS AS APP USER
sudo -u $APP_USER bash << EOF
# -------[script begins]-------
echo "----- LOGINED AS ----"
whoami

# Create user group and assign home directory
echo "----- Provision: Create Virtual Environment..."
cd $APP_PATH
pwd

# if project already exists
if [ "$prj_exists" == y ] ; then
git clone $git_repo .
fi

pyvenv-3.4 --without-pip . # because of Ubuntu 14.04 PIP3 issue we create venv without pip
source bin/activate
python --version

echo "----- VEnv: Install PIP..."
wget https://bootstrap.pypa.io/ez_setup.py -O - | python
wget https://bootstrap.pypa.io/get-pip.py
python get-pip.py

echo "----- PIP: Install Requirements for APP..."
pip install --no-cache-dir psycopg2
pip install gunicorn
pip install --no-cache-dir setproctitle
pip install django

# create django app if dont exists
if [ "$prj_exists" != y ] ; then
django-admin startproject $APP_NAME
fi

# Create log folder for logs
mkdir -p $APP_PATH/logs/
touch $APP_PATH/logs/gunicorn_supervisor.log 



# -------[script ends]-------
EOF






# ------------------------------------------------------------------------------
# Set up gunicorn_start file
echo "----- Gunicorn: Set up gunicorn_start file..."
sed 's|#{APP_USER}|'$APP_USER'|g' $script_dir/../tpl/gunicorn_start.sh > $script_dir/../tpl/gunicorn_start.bak
sed -i -e  's|#{APP_NAME}|'$APP_NAME'|g' -e 's|#{APP_PATH}|'$APP_PATH'|g' -e 's|#{APP_USER_GROUP}|'$APP_USER_GROUP'|g' $script_dir/../tpl/gunicorn_start.bak
sudo mv -i $script_dir/../tpl/gunicorn_start.bak  $APP_PATH/bin/gunicorn_start
sudo chmod u+x $APP_PATH/bin/gunicorn_start
sudo chown -R $APP_USER:$APP_USER_GROUP $APP_PATH/bin/gunicorn_start



# Setup of Supervisor
echo "----- Supervisor: Starting and monitoring..."
sed 's|#{APP_USER}|'$APP_USER'|g' $script_dir/../tpl/supervisor.conf > $script_dir/../tpl/supervisor.conf.bak
sed -i -e  's|#{APP_NAME}|'$APP_NAME'|g' -e 's|#{APP_PATH}|'$APP_PATH'|g' $script_dir/../tpl/supervisor.conf.bak
sudo mv -i $script_dir/../tpl/supervisor.conf.bak  /etc/supervisor/conf.d/$APP_NAME.conf
# operate
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart $APP_NAME


# Setup of Nginx
echo "----- Nginx: Create an Nginx virtual server configuration..."
sed 's|#{APP_NAME}|'$APP_NAME'|g' $script_dir/../tpl/nginx.server > $script_dir/../tpl/nginx.server.bak
sed -i -e  's|#{APP_SERVER}|'$APP_SERVER'|g' -e 's|#{APP_PATH}|'$APP_PATH'|g' $script_dir/../tpl/nginx.server.bak
sudo mv -i $script_dir/../tpl/nginx.server.bak  /etc/nginx/sites-available/$APP_NAME
sudo ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/$APP_NAME
sudo service nginx restart 



echo "============================================="
echo "| Now you'll be able to see the django-app! |"
echo "============================================="


# ------------------------------------------------------------------------------
# Create ssh key
echo "Would you like to create SSH key? (y/n)"
read -e ssh_keygen
if [ "$ssh_keygen" == y ] ; then

	read -p "Change the URI (URL) for a remote Git repository? (y/n): " change_repo_url
	if [ "$change_repo_url" == y ] ; then
		read -p "Write new URL for repository: " new_git_repo
	fi


sudo -u $APP_USER bash << EOF
# ---- [virtual env] ----

whoami
cd $APP_PATH
source bin/activate
pwd

echo -e  'y\n' | ssh-keygen -t rsa -C "$APP_NAME@$APP_SERVER" -N "" -f $APP_PATH/.ssh/id_rsa
cat $APP_PATH/.ssh/id_rsa.pub

if [ "$change_repo_url" == y ] ; then
git remote set-url origin $new_git_repo
fi
# --- [/virtual env] ----
EOF

fi



exit 0