from nodesource/node:precise
maintainer Adam Alpern <adam.alpern@gmail.com>

run	apt-get -y update

# Install required packages
run	apt-get -y install \
    python-ldap python-cairo python-django python-twisted python-django-tagging \
    python-simplejson python-memcache python-pysqlite2 python-support python-pip \
    gunicorn supervisor nginx-light \
    git curl

run	pip install bpython
run	pip install whisper
run	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/lib" carbon
run	pip install --install-option="--prefix=/var/lib/graphite" --install-option="--install-lib=/var/lib/graphite/webapp" graphite-web

# Add system service config
add	./nginx.conf /etc/nginx/nginx.conf
add	./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Add graphite config
add	./graphite/initial_data.json /var/lib/graphite/webapp/graphite/initial_data.json
add	./graphite/local_settings.py /var/lib/graphite/webapp/graphite/local_settings.py
add	./graphite/carbon.conf /var/lib/graphite/conf/carbon.conf
add	./graphite/storage-schemas.conf /var/lib/graphite/conf/storage-schemas.conf
run	mkdir -p /var/lib/graphite/storage/whisper
run	touch /var/lib/graphite/storage/graphite.db /var/lib/graphite/storage/index
run	chown -R www-data /var/lib/graphite/storage
run	chmod 0775 /var/lib/graphite/storage /var/lib/graphite/storage/whisper
run	chmod 0664 /var/lib/graphite/storage/graphite.db
run	cd /var/lib/graphite/webapp/graphite && python manage.py syncdb --noinput

# Tessera
add ./config.py /var/lib/tessera/config.py
run	git clone https://github.com/urbanairship/tessera.git /src/tessera
workdir	/src/tessera
run	pip install -r requirements.txt
run	pip install -r dev-requirements.txt
run	npm install -g grunt-cli
run	npm install
run	grunt
run	invoke db.init
run	invoke run & sleep 5 && invoke json.import 'demo/*.json'

# Nginx
expose	:80
# Carbon line receiver port
expose	:2003
# Carbon pickle receiver port
expose	:2004
# Carbon cache query port
expose	:7002

cmd	["/usr/bin/supervisord"]
