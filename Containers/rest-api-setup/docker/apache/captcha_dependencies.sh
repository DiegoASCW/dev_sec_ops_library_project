#!/bin/bash

# Instala mysqli e pdo_mysql
docker-php-ext-configure mysqli \
    && docker-php-ext-install -j"$(nproc)" mysqli \
    && docker-php-ext-install -j"$(nproc)" pdo_mysql \
    && docker-php-ext-enable mysqli pdo_mysql

# Instala GD e dependências
apt-get update && apt-get install -y \
    libfreetype-dev \
    libjpeg62-turbo-dev \
    libpng-dev

# aqui só mágica justifica o que é
docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd \
    && docker-php-ext-enable gd

a2enmod rewrite
