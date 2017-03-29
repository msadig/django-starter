#!/usr/bin/env bash

# Any subsequent(*) commands which fail will cause the shell script to exit immediately
set -e

# DEFAULT VARIABLES
VERSION="1.1"
ERROR_STATUS=0
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Get config
if [ -f ${CURRENT_PATH}/../config.txt ]; then
	. ${CURRENT_PATH}/../config.txt
else
  echo "---> You should have config file imported <---"
  exit 1
fi


# ------------------------
# Usage
function usage {
    clear
    echo -e "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"
    echo -e "\t Django Project Starter v$VERSION"
    echo -e "\t Sadig Muradov - sadig@muradov.org"
    echo -e "\t Specs: Ubuntu 14.04\n"
    echo -e "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=\n"
    echo -e "Usage: bash $0 <COMMAND>"
    echo -e "\nCommands:"

    echo -e "\t setup \t\t\t - Setup and create config file"
    echo -e "\t start \t\t\t - Start deploy django app to '$APP_PATH'"
    echo -e "\t destroy \t\t - Destroy django app"
    exit 1
}

# ------------------------
# Initial setup
function update_conf {
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

  	sed 's|#{server}|'$server'|g' ${CURRENT_PATH}/../tpl/conf.bak > ${CURRENT_PATH}/../config.txt
  	sed -i.bak -e 's|#{appuser}|'$appuser'|g' -e 's|#{appname}|'$appname'|g' -e 's|#{apppath}|'$apppath'|g' -e 's|#{db_user}|'$db_user'|g' -e 's|#{db_password}|'$db_password'|g' -e 's|#{db_name}|'$db_name'|g' ${CURRENT_PATH}/../config.txt
  	rm ${CURRENT_PATH}/../config.txt.bak

  	echo "Process complated, now run the 'bash ./django-starter/script/app.sh' command for the creating Django app with the paremeters you've defined."
  fi
}

# ------------------------
# Banner
function install_banner {
    clear
    echo "************************************************************************"
    echo "!!!!!!!!!!!!!!!!!!!! Start Installing as `whoami`... !!!!!!!!!!!!!!!!!!!"
    echo "************************************************************************"
    echo ""
}

# ------------------------
# Update & Upgrade
function update {
    echo "----- Provision: System Update & Upgrade..."
    sudo aptitude -y update
    sudo aptitude -y upgrade
}

# ------------------------
# Install Requirements
function install_requirements {
    echo "----- Provision: Installing SUDO Requirements..."
    sudo aptitude install -y postgresql postgresql-contrib libpq-dev python-dev supervisor nginx git python3-pip
}


# ------------------------
# Install Requirements
function install_venv {
  # Note: in the new version of the Ubuntu pyvenv not preinstalled
  if ! pyvenv_3="$(type -p pyvenv-3.4)" || [ -z "$pyvenv_3" ]; then
    echo "----- Requirements: install pyvenv-3.4"
    sudo apt-get install python3.4-venv # http://askubuntu.com/a/528625, http://stackoverflow.com/a/7522866/968751
  fi
}


# ------------------------
# Set up gunicorn_start file
function setup_gunicorn {
    echo "----- Gunicorn: Set up gunicorn_start file..."
    sed 's|#{APP_USER}|'$APP_USER'|g' $CURRENT_PATH/../tpl/gunicorn_start.sh > $CURRENT_PATH/../tpl/gunicorn_start.bak
    sed -i -e  's|#{APP_NAME}|'$APP_NAME'|g' -e 's|#{APP_PATH}|'$APP_PATH'|g' -e 's|#{APP_USER_GROUP}|'$APP_USER_GROUP'|g' $CURRENT_PATH/../tpl/gunicorn_start.bak
    sudo mv -i $CURRENT_PATH/../tpl/gunicorn_start.bak  $APP_PATH/bin/gunicorn_start
    sudo chmod u+x $APP_PATH/bin/gunicorn_start
    sudo chown -R $APP_USER:$APP_USER_GROUP $APP_PATH/bin/gunicorn_start
}


# ------------------------
# Set up Supervisor
function setup_supervisor {
  echo "----- Supervisor: Starting and monitoring..."
  sed 's|#{APP_USER}|'$APP_USER'|g' $CURRENT_PATH/../tpl/supervisor.conf > $CURRENT_PATH/../tpl/supervisor.conf.bak
  sed -i -e  's|#{APP_NAME}|'$APP_NAME'|g' -e 's|#{APP_PATH}|'$APP_PATH'|g' $CURRENT_PATH/../tpl/supervisor.conf.bak
  sudo mv -i $CURRENT_PATH/../tpl/supervisor.conf.bak  /etc/supervisor/conf.d/$APP_NAME.conf
  # operate
  sudo supervisorctl reread
  sudo supervisorctl update
  sudo supervisorctl restart $APP_NAME
}


# ------------------------
# Set up Nginx
function setup_nginx {
  if [ ! -f /etc/nginx/sites-available/$APP_NAME ]; then
    echo "----- Nginx: Create an Nginx virtual server configuration..."
    sed 's|#{APP_NAME}|'$APP_NAME'|g' $CURRENT_PATH/../tpl/nginx.server > $CURRENT_PATH/../tpl/nginx.server.bak
    sed -i -e  's|#{APP_SERVER}|'$APP_SERVER'|g' -e 's|#{APP_PATH}|'$APP_PATH'|g' $CURRENT_PATH/../tpl/nginx.server.bak
    sudo mv -i $CURRENT_PATH/../tpl/nginx.server.bak  /etc/nginx/sites-available/$APP_NAME
    sudo ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/$APP_NAME
  fi
  sudo service nginx restart
}


# ------------------------
# Install Requirements
function create_app_user {
  # Create user, group and assign home directory IF not exists
  if ! id -u $APP_USER > /dev/null 2>&1; then
  	echo "----- Provision: Create APP User and assign home directory..."
  	if ! grep -q $APP_USER_GROUP /etc/group; then
  	   sudo groupadd --system $APP_USER_GROUP
  	fi
  	randompw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 30 | head -n 1) #random password
  	sudo useradd --system --gid $APP_USER_GROUP --shell /bin/bash --home $APP_PATH $APP_USER

  	# Assign the password to the user.
  	# Password is passed via stdin, *twice* (for confirmation).
  	sudo passwd $APP_USER <<< "$randompw"$'\n'"$randompw"
  	cecho green "=============================================================================="
  	cecho green "******************************************************************************"
  	cecho green " "
  	cecho green "User: '$APP_USER' has been created with the following password: $randompw"
  	cecho green " "
  	cecho green "******************************************************************************"
  	cecho green "=============================================================================="
  fi

  if [ ! -f ${APP_PATH} ]; then
    # Create apps user and assign app directory to him
    sudo mkdir -p $APP_PATH
    sudo chown $APP_USER $APP_PATH

    # Give write permission to app user
    sudo chown -R $APP_USER:$APP_USER_GROUP $APP_PATH
    sudo chmod -R g+w $APP_PATH
    sudo usermod -a -G users `whoami`
  fi
}


# ------------------------
# Database creation
function create_db {
  sudo su - postgres << EOF
    # -------[script begins]-------
    if ! psql -lqt | cut -d \| -f 1 | grep -qw ${APP_DB_NAME}; then
      echo "----- PostgreSQL: Creating database and user..."
      psql -c "CREATE USER $APP_DB_USER WITH PASSWORD '$APP_DB_PASSWORD';"
      createdb --owner $APP_DB_USER $APP_DB_NAME
    fi
    # -------[script ends]-------
EOF
}


# ------------------------
# Create Virtual Environment for project
function create_project {
  # If wants create existing project
  read -p "Do you wish to create existing project? (y/n): " prj_exists
  if [ "$prj_exists" == y ] ; then
    read -p "Please provide HTTP URL for the GIT repository: " git_repo
  fi

  # RUN SCRIPTS AS APP USER
  sudo -u $APP_USER bash << EOF
    # -------[script begins]-------
    echo "----- LOGINED AS `whoami` ----"
    # Create user group and assign home directory
    echo "----- Provision: Create Virtual Environment..."
    cd $APP_PATH
    pwd

    # if project already exists
    if [ "$prj_exists" == y ] ; then
      git clone $git_repo .
    fi

    pyvenv-3.4 --without-pip . # because of Ubuntu 14.04 PIP3 issue we create venv without pip
    if [ ! $? -eq 0 ]; then
        # if pyvenv-3.4 fails then try python3 venv
        python3 -m venv --without-pip .
    fi
    source bin/activate
    python --version

    if [ -d ${DJANGO_PATH} ]; then
      exit $ERROR_STATUS
    fi

    echo "----- Venv: Install PIP..."
    wget https://bootstrap.pypa.io/ez_setup.py -O - | python
    wget https://bootstrap.pypa.io/get-pip.py
    python get-pip.py

    echo "----- PIP: Install Requirements for APP..."
    if [ "$prj_exists" == y ] && [ -f ${DJANGO_PATH}/requirements.txt ]; then
      pip install --no-cache-dir -r ${DJANGO_PATH}/requirements.txt
    else
      pip install --no-cache-dir psycopg2
      pip install gunicorn
      pip install --no-cache-dir setproctitle
      pip install django
    fi

    # create django app if dont exists
    if [ "$prj_exists" != y ] ; then
      django-admin startproject $APP_NAME
    fi

    # Create log folder for logs
    mkdir -p $APP_PATH/logs/
    touch $APP_PATH/logs/gunicorn_supervisor.log
    # -------[script ends]-------
EOF
}


# ------------------------
# Create ssh key
function create_ssh_key {
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
      cd $APP_PATH && source bin/activate
      pwd

      echo -e  'y\n' | ssh-keygen -t rsa -C "$APP_NAME@$APP_SERVER" -N "" -f $APP_PATH/.ssh/id_rsa
      cat $APP_PATH/.ssh/id_rsa.pub

      if [ "$change_repo_url" == y ] ; then
      git remote set-url origin $new_git_repo
      fi
      # --- [/virtual env] ----
EOF
  fi
}


# ------------------------
# Destroy App
function destroy_app {
    clear
    echo "************************************************************************"
    echo "!!!!!!!!!!!!!!!!!!!!!! Destroy App as `whoami`... !!!!!!!!!!!!!!!!!!!!!!"
    echo "************************************************************************"
    echo ""
    read -p "Are you sure you want DELETE app? (y/n): " confirm_delete

    if [ "$confirm_delete" == y ] ; then

        if [ -f /etc/nginx/sites-enabled/$APP_NAME ]; then
          # Remove the virtual server from Nginx sites-enabled folder
          sudo rm /etc/nginx/sites-enabled/$APP_NAME
          sudo rm /etc/nginx/sites-available/$APP_NAME
          # Restart Nginx:
          sudo service nginx restart
        fi

        if [ -f /etc/supervisor/conf.d/$APP_NAME.conf ]; then
          # Stop the application with Supervisor:
          sudo supervisorctl stop $APP_NAME
          # Remove the application from Supervisor’s control scripts directory:
          sudo rm /etc/supervisor/conf.d/$APP_NAME.conf
        fi

        if [ -d $APP_PATH ]; then
          # If you never plan to use this application again, you can now remove its entire directory from webapps:
          sudo rm -r $APP_PATH
        fi

sudo su - postgres << EOF
        # -------[script begins]-------
        if psql -lqt | cut -d \| -f 1 | grep -qw ${APP_DB_NAME}; then
          dropdb $APP_DB_NAME
          psql -c "DROP USER $APP_DB_USER;"
        fi
        # -------[script ends]-------
EOF
  fi
}



################
#### TOOLS  ####
################

cecho() {
  local code="\033["
  case "$1" in
    black  | bk) color="${code}0;30m";;
    red    |  r) color="${code}1;31m";;
    green  |  g) color="${code}1;32m";;
    yellow |  y) color="${code}1;33m";;
    blue   |  b) color="${code}1;34m";;
    purple |  p) color="${code}1;35m";;
    cyan   |  c) color="${code}1;36m";;
    gray   | gr) color="${code}0;37m";;
    *) local text="$1"
  esac
  [ -z "$text" ] && local text="$color$2${code}0m"
  echo -e "$text"
}


################
#### START  ####
################

COMMAND=${@:$OPTIND:1}
ARG1=${@:$OPTIND+1:1}

#CHECKING PARAMS VALUES
case ${COMMAND} in

    setup)
      update_conf
    ;;

    start | deploy)
  		install_banner
      update
      install_requirements
      install_venv
      create_app_user
      create_db
      create_project
      setup_gunicorn
      setup_supervisor
      setup_nginx
      create_ssh_key
  	;;

    destroy | remove )
  		destroy_app
  	;;

    *)
        if [[ $COMMAND != "" ]]; then
            echo "Error: Unknown command: $COMMAND"
            ERROR_STATUS=1
        fi
        usage
    ;;

esac

exit $ERROR_STATUS
