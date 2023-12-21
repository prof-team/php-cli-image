FROM php:8.1-cli

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y \
        cron \
        supervisor \
        nano \
        htop \
        git \
        wget \
        curl \
        logrotate \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libcurl4-gnutls-dev \
        libxpm-dev \
        libvpx-dev \
        libonig-dev \
        mediainfo

# Some basic extensions
RUN docker-php-ext-install -j$(nproc) mbstring opcache

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
        sockets

# Install Memcached
RUN apt-get install -y libmemcached-dev zlib1g-dev
RUN pecl install memcached
RUN docker-php-ext-enable memcached

# Install PECL Redis
RUN pecl install redis && docker-php-ext-enable redis

# Install APCu backward compatibility
RUN pecl install apcu && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini

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

# for test coverage
RUN  pecl install pcov && docker-php-ext-enable pcov

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- \
        --filename=composer \
        --install-dir=/usr/local/bin

# install php-cs-fixer
RUN curl -L https://cs.symfony.com/download/php-cs-fixer-v3.phar -o php-cs-fixer && \
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
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
