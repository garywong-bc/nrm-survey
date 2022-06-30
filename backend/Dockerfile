ARG DOCKER_REGISTRY=docker.io/library
FROM $DOCKER_REGISTRY/php:8.0-apache
# Derived from https://github.com/adamzammit/limesurvey-docker

ENV DOCKERIZE_VERSION v0.6.1

ARG GITHUB_REPO=https://github.com/LimeSurvey/LimeSurvey
ARG GITHUB_TAG=5.3.21+220620
# NOTE: Need to update the same ARGs in ../openshift/limesurvey.bc.yaml

# install the PHP extensions we need
RUN apt-get update \
    && apt-get install -y unzip libc-client-dev libfreetype6-dev libmcrypt-dev libpng-dev libjpeg-dev \
    libldap2-dev zlib1g-dev libkrb5-dev libtidy-dev libzip-dev libsodium-dev \
    libpq-dev vim wget \
    && rm -rf /var/lib/apt/lists/* \
    && docker-php-ext-configure gd --with-freetype=/usr/include/  --with-jpeg=/usr \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install gd mysqli pdo pdo_mysql opcache zip iconv tidy \
    && docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ \
    && docker-php-ext-install ldap \
    && docker-php-ext-configure imap --with-imap-ssl --with-kerberos \
    && docker-php-ext-install imap \
    && docker-php-ext-install sodium \
    && pecl install mcrypt-1.0.5 \
    && docker-php-ext-enable mcrypt \
    && docker-php-ext-install exif \
    pdo pdo_pgsql pgsql \
    && a2enmod rewrite

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN wget https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz \
    && useradd --comment "Apache User, integrated with OpenShift default user" -g root -m -u 1001 default_user  

COPY nrm-config/config-*-pgsql.php /tmp

RUN set -x; \
    wget "$GITHUB_REPO/archive/refs/tags/$GITHUB_TAG.tar.gz" \
    && tar -zxf $GITHUB_TAG.tar.gz --strip-components=1 \
    && rm $GITHUB_TAG.tar.gz \
    && mkdir -p /var/lime/application/config \
    && mkdir -p /var/lime/upload \
    && mkdir -p /var/lime/plugins \
    && cp /tmp/config-*-pgsql.php /var/www/html/application/config/ \
    && chown -R default_user:root /var/www/html \
    && chmod -R g+w /var/www/html \
    && cp -dpR /var/www/html/application/config/* /var/lime/application/config \
    && cp -dpR /var/www/html/upload/* /var/lime/upload \
    && cp -dpR /var/www/html/plugins/* /var/lime/plugins

#Set PHP defaults for Limesurvey (allow bigger uploads)
RUN { \
    echo 'memory_limit=256M'; \
    echo 'upload_max_filesize=128M'; \
    echo 'post_max_size=128M'; \
    echo 'max_execution_time=120'; \
    echo 'max_input_vars=10000'; \
    echo 'date.timezone=UTC'; \
    } > /usr/local/etc/php/conf.d/uploads.ini

# Set Apache defaults for Limesurvey (ServerName and default port), and
# also enable "/server-status?auto" for integration with OCP4 Sysdig

RUN sed -i '$ a ServerName localhost'     /etc/apache2/apache2.conf   \
    && sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/ports.conf    \
    && sed -i 's/<VirtualHost \*\:80>/<VirtualHost *:8080>/g' /etc/apache2/sites-enabled/000-default.conf \
    && sed -i '/RewriteCond %{REQUEST_FILENAME} !-d$/a \    RewriteCond %{REQUEST_URI} !=/server-status' /var/www/html/.htaccess

VOLUME ["/var/www/html/plugins"]
VOLUME ["/var/www/html/upload"]
VOLUME ["/var/www/html/application/config"]

COPY docker-entrypoint.sh nrm-check-install.php /usr/local/bin/

USER default_user
