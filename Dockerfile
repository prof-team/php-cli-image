FROM php:7.3-cli

RUN apt-get update && apt-get install -y \
        cron \
        python-setuptools \
        nano \
        htop \
        git \
        logrotate \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev

RUN easy_install pip \
    && pip install supervisor \
    && pip install superslacker

RUN docker-php-ext-install -j$(nproc) iconv
RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/
RUN docker-php-ext-install -j$(nproc) gd

# Some basic extensions
RUN docker-php-ext-install -j$(nproc) json mbstring opcache pdo pdo_mysql mysqli

# Install pgsql
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo_pgsql pgsql

# Intl
RUN apt-get install -y libicu-dev
RUN docker-php-ext-install -j$(nproc) intl

# Install bcmath
RUN docker-php-ext-install bcmath

# Install Memcached
RUN apt-get install -y libmemcached-dev zlib1g-dev
RUN pecl install memcached
RUN docker-php-ext-enable memcached

# Install APCu and APC backward compatibility
RUN pecl install apcu \
    && pecl install apcu_bc-1.0.3 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# Install mongo
RUN apt-get install -y \
        libssl-dev \
    && pecl install mongodb \
    && docker-php-ext-enable mongodb

# Install ldap
RUN apt-get install libldap2-dev -y && \
    docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install ldap

# Install zip
RUN apt-get install -y \
        libzip-dev \
        zip \
  && docker-php-ext-configure zip --with-libzip \
  && docker-php-ext-install zip

RUN docker-php-ext-install exif

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
# parallel install plugin
RUN composer global require hirak/prestissimo

RUN apt-get clean && apt-get autoclean && apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /var/log/php

ADD ./conf.d/*.ini /usr/local/etc/php/conf.d/

ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD docker-entrypoint.sh /entrypoint.sh

WORKDIR /var/www
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]