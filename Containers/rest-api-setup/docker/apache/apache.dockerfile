FROM php:8.2-apache

COPY ./captcha_dependencies.sh /tmp

RUN bash /tmp/captcha_dependencies.sh

EXPOSE 80