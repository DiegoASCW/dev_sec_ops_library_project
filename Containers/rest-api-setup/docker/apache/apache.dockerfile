FROM php:8.2-apache

COPY ./Projeto_Web/site /var/www/html

COPY ./Containers/rest-api-setup/docker/apache/captcha_dependencies.sh /tmp

RUN bash /tmp/captcha_dependencies.sh

EXPOSE 80