



#### on all hosts
* Install this PIP packages: `flask`, `flask-mysql`, `markupsafe`

#### Debian
* Install this apt/deb packages: `libmysqlclient-dev`, `python-dev`, `python-pip`, `gunicorn`

### Backend
* Install the `mysql-server` package
* Configure mysql to listen on the address `0.0.0.0` -> `bind-address = 0.0.0.0`
* Download the [mysqldump]



## Configuration
* Create a "version" file `/tmp/app-version.txt` with the tag/branch
* Create the dbhost file `/etc/dbhost.cfg` and configure your database host. [Example](dbhost.cfg)


## Run your application

### with python

```bash
cd <install-dir>
python app.py
```

### with gunicorn

```bash
gunicorn --chdir <install-dir> --bind 0.0.0.0:8000 --daemon wsgi:app
```


## Test URLs
* http://web1.[name].lab:8000/
* http://web2.[name].lab:8000/
