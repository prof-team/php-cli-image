FROM php:7.4-cli

RUN apt-get update && apt-get install -y \
        cron \
        python-pip \
        nano \
        htop \
        git \
        wget \
        logrotate \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libcurl4-gnutls-dev \
        libxpm-dev \
        libvpx-dev \
        libonig-dev

RUN pip install supervisor \
    && pip install superslacker

# Some basic extensions
RUN docker-php-ext-install -j$(nproc) json mbstring opcache

# Install gd
RUN docker-php-ext-configure gd --with-freetype=/usr/include/ --with-jpeg=/usr/include/
RUN docker-php-ext-install gd

# Install mysql
RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql mysqli

# Install pgsql
RUN apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo_pgsql pgsql

# Intl
RUN apt-get install -y libicu-dev
RUN docker-php-ext-install -j$(nproc) intl

# Install amqp
RUN apt-get install -y \
        librabbitmq-dev \
        libssh-dev \
    && docker-php-ext-install \
        bcmath \
        sockets \
    && pecl install amqp \
    && docker-php-ext-enable amqp

# Install Memcached
RUN apt-get install -y libmemcached-dev zlib1g-dev
RUN pecl install memcached
RUN docker-php-ext-enable memcached

# Install PECL Redis
RUN pecl install redis && docker-php-ext-enable redis

# Install APCu and APC backward compatibility
RUN pecl install apcu \
    && pecl install apcu_bc \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# Install mongodb
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
        unzip \
  && docker-php-ext-configure zip \
  && docker-php-ext-install zip

RUN docker-php-ext-install exif

# Install xdebub
RUN pecl install xdebug

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin

# install php-cs-fixer
RUN curl -L https://cs.symfony.com/download/php-cs-fixer-v2.phar -o php-cs-fixer && \
    chmod a+x php-cs-fixer && \
    mv php-cs-fixer /usr/local/bin/php-cs-fixer

RUN apt-get clean && apt-get autoclean && apt-get autoremove -y
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir -p /var/log/php

ADD ./conf.d/*.ini /usr/local/etc/php/conf.d/

ADD supervisord.conf /etc/supervisor/supervisord.conf
ADD docker-entrypoint.sh /entrypoint.sh

WORKDIR /var/www
ENTRYPOINT ["bash", "/entrypoint.sh"]
CMD ["/usr/local/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]