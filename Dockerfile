# -----------------------------------------------------------------------------
# docker-pinry
#
# Builds a basic docker image that can run Pinry (http://getpinry.com) and serve
# all of it's assets, there are more optimal ways to do this but this is the
# most friendly and has everything contained in a single instance.
#
# Authors: Isaac Bythewood
# Updated: Mar 29th, 2016
# Require: Docker (http://www.docker.io/)
# -----------------------------------------------------------------------------


# Base system is the LTS version of Ubuntu.
FROM ubuntu:14.04

ENV PYENV_ROOT /usr/local/pyenv
ENV PATH /usr/local/pyenv/shims:/usr/local/pyenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.iij.ad.jp/pub/linux/ubuntu/archive/%g" /etc/apt/sources.list
RUN apt-get update && \
    apt-get install -y git mercurial build-essential libssl-dev libbz2-dev libreadline-dev libsqlite3-dev curl && \
    curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
RUN pyenv install 2.7.14 && pyenv global 2.7.14
RUN apt-get -y install nginx sqlite3 pwgen nodejs-legacy npm python-imaging libjpeg8-dev
RUN npm install -g bower
RUN mkdir -p /srv/www/; cd /srv/www/; git clone https://github.com/haoling/pinry.git
RUN mkdir /srv/www/pinry/logs; mkdir /srv/www/pinry/uwsgi; mkdir /data
RUN cd /srv/www/pinry; pip install -r requirements.txt; pip install uwsgi supervisor; chown -R www-data:www-data .

# Fix permissions
ADD ./pinry/settings.py /srv/www/pinry/pinry/settings.py
RUN chown -R www-data:www-data /srv/www


# Load in all of our config files.
ADD ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD ./nginx/sites-enabled/default /etc/nginx/sites-enabled/default
ADD ./uwsgi/apps-enabled/pinry.ini /etc/uwsgi/apps-enabled/pinry.ini
ADD ./supervisor/supervisord.conf /etc/supervisor/supervisord.conf
ADD ./supervisor/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
ADD ./supervisor/conf.d/uwsgi.conf /etc/supervisor/conf.d/uwsgi.conf


# Fix permissions
ADD ./scripts/start /start
RUN chown -R www-data:www-data /data; chmod +x /start
RUN mkdir /var/log/supervisor /var/log/uwsgi

ENV PYTHONPATH /usr/local/pyenv/versions/2.7.14/lib/python2.7:/usr/local/pyenv/versions/2.7.14/lib/python2.7/lib-dynload:/usr/local/pyenv/versions/2.7.14/lib/python2.7/site-packages


# 80 is for nginx web, /data contains static files and database /start runs it.
expose 80
volume ["/data"]
cmd    ["/start"]

