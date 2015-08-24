# django-starter
Automates the creation of a simple Django app which uses PostgreSQL, Gunicorn, Supervisor, Nginx, etc.

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

### Usage
Run:
```
$ curl -LO https://raw.githubusercontent.com/msadig/django-starter/master/script/setup.sh && bash setup.sh
```

Then open the scripts folder and run app.sh for creating django app
```
$ cd ./django-starter-master/scripts
$ bash app.sh
```

You can change configuration of the Django app from config.txt
