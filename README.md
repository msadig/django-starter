# django-starter
Automates the creation of a simple Django app which uses PostgreSQL, Gunicorn, Supervisor, Nginx, etc.

##This script sets up: 
- Python2.7 & Python3.4
- Django
- Git
- Gunicorn
- Supervisior
- Nginx
- PostgreSQL (also creates a database for the project and a user that can access it)

NOTE: Tested only on Ubuntu 14.04

### Usage
Run:
```
$ curl -LO https://raw.githubusercontent.com/msadig/django-starter/master/script/setup.sh && bash setup.sh
```
You can to define Django app parameters manually (`nano ./django-master/config.txt`) or create config file on the fly.


After defining the parameters of future Djangp app, open the starter folder and run app.sh for the creating Django app
```
$ cd ./django-starter
$ bash script/app.sh
```




### Credits:
- http://michal.karzynski.pl/blog/2013/06/09/django-nginx-gunicorn-virtualenv-supervisor/
- https://gist.github.com/damienstanton/f63c8aed8f4a432cfcf2
- https://gist.github.com/sspross/330b5b1f08ada7b70c24
- https://pypi.python.org/pypi/setuptools
- http://stackoverflow.com/a/17517654/968751
- https://pip.pypa.io/en/latest/installing.html
- https://confluence.atlassian.com/pages/viewpage.action?pageId=270827678
- http://stackoverflow.com/a/22947716/968751
- http://superuser.com/a/468163
- http://stackoverflow.com/a/8998789/968751
- http://stackoverflow.com/a/24696790/968751
- http://stackoverflow.com/a/11603385/968751
- http://askubuntu.com/a/682616 - new virtual envoirenment for paython3.4
