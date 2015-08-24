# Fabfile to:
# - update the remote system(s)
#    - download and install an application

# Some tutorials:
#   - https://www.digitalocean.com/community/tutorials/how-to-use-fabric-to-automate-administration-tasks-and-deployments
#   - http://docs.fabfile.org/en/latest/tutorial.html
#   - https://confluence.atlassian.com/pages/viewpage.action?pageId=270827678

# Import Fabric's API module
from fabric.api import *


# Set the remote
env.hosts = ['192.168.101.11', ]
env.user = "test_user"



# Deployment parametres
app_name = 'hello_django'
app_user = 'test_django'
app_user_pasw = ''
app_supervisor = app_name
app_dir = '/webapps/test_app/' + app_name
dev_dir = '/webapps/test_app/' + app_name





# ------------------------------------------------------------
# Settings.py

def switch_debug(frm, to):
    """
    >>> text = 'salam %(name)s, yaxisan? Men %(me)s'
    >>> text % ({'name':'ahmed', 'me': 'sadiq'})
    """
    local('cp %(app_dir)s/%(main_app)s/settings.py %(app_dir)s/%(main_app)s/settings.bak' % (
    {'app_dir': app_dir, 'main_app': main_app}))

    sed = "sed 's/^DEBUG = %(from)s/DEBUG = %(to)s/' %(app_dir)s/%(main_app)s/settings.bak > %(app_dir)s/%(main_app)s/settings.py"
    local(sed % ({
                     'from': frm,
                     'to': to,
                     'app_dir': app_dir,
                     'main_app': main_app
                 }))

    local('rm %(app_dir)s/%(main_app)s/settings.bak' % ({'app_dir': app_dir, 'main_app': main_app}))


def prepare():
    switch_debug('True', 'False')
    backup_local()
    switch_debug('False', 'True')


def backup_local():
    local('git pull')
    local('git add .')

    print('Enter commit comment:')
    comment = raw_input()

    local('git commit -m "%s"' % comment)
    local('git push')


# ------------------------------------------------------------
# Git functions
def git_fetch():
    """
        Logins to the server as the app user of Ubuntu
        and gets latest updates from git and replaces files accordingly
    """
    with settings(user=app_user, password=app_user_pasw):
        with cd(app_dir):
            run('git fetch origin')
            run('git status')
            run('git reset --hard origin/master')
            run('git status')
            switch_server_debug('True', 'False')
            run('git status')


def git_revert(commit):
    """
        Revert back to certain commit.
        http://stackoverflow.com/a/4114122/968751

        - Usage:
          $: fab git_revert:commit='f4f6dab'
    """
    with settings(user=app_user, password=app_user_pasw):
        with cd(app_dir):
            run('git checkout -b old-state %s' % commit)
            switch_server_debug('True', 'False')
            run('git status')


# ------------------------------------------------------------
# Server commands for deploy

def switch_server_debug(frm, to):
    """
    >>> text = 'salam %(name)s, yaxisan? Men %(me)s'
    >>> text % ({'name':'ahmed', 'me': 'sadiq'})
    """
    run('cp %(app_dir)s/%(main_app)s/settings.py %(app_dir)s/%(main_app)s/settings.bak' % (
    {'app_dir': app_dir, 'main_app': main_app}))

    sed = "sed 's/^DEBUG = %(from)s/DEBUG = %(to)s/' %(app_dir)s/%(main_app)s/settings.bak > %(app_dir)s/%(main_app)s/settings.py"
    run(sed % ({
                   'from': frm,
                   'to': to,
                   'app_dir': app_dir,
                   'main_app': main_app
               }))

    run('rm %(app_dir)s/%(main_app)s/settings.bak' % ({'app_dir': app_dir, 'main_app': main_app}))


def update_codes():
    """
        Restart Supervisor and Ngnix for runing changed codes
    """
    with cd(app_dir):
        sudo('supervisorctl restart %s' % app_supervisor)
        sudo('sudo service nginx restart')


# ------------------------------------------------------------

def deploy():
    # get latest codes
    git_fetch()

    # run latest code
    update_codes()


# ------------------------------------------------------------

def vagrant():
    with lcd(dev_dir):
        local('sudo supervisorctl restart %s' % app_supervisor)
        local('sudo service nginx restart')
