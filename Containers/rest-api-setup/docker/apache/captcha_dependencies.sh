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

docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd \
    && docker-php-ext-enable gd

# Ativa mod_rewrite do Apache
a2enmod rewrite

# (Reiniciar apache aqui não é necessário — Docker vai gerenciar isso)
