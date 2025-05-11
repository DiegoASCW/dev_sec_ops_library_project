#!/bin/bash

docker-php-ext-configure mysqli \
        && docker-php-ext-install -j$(nproc) mysqli

apt-get update && apt-get install -y \
                libfreetype-dev \
                libjpeg62-turbo-dev \
                libpng-dev

docker-php-ext-configure gd --with-freetype --with-jpeg \
        && docker-php-ext-install -j$(nproc) gd \
        && docker-php-ext-enable gd

/usr/sbin/a2enmod rewrite