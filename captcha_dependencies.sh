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
    libpng-dev \
    libapache2-mod-security2 \
    modsecurity-crs

# aqui só mágica justifica o que é
docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd \
    && docker-php-ext-enable gd

a2enmod rewrite

mv /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

a2enmod security2

/etc/init.d/apache2 restart

sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf

ln -s /usr/share/modsecurity-crs /usr/share/modsecurity-crs/activated_rules

/etc/init.d/apache2 restart