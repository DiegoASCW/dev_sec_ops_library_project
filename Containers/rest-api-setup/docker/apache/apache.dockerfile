FROM php:8.2-apache

COPY ./captcha_dependencies.sh /tmp

#CMD ["bash", "/tmp/captcha_dependencies.sh"]

RUN bash /tmp/captcha_dependencies.sh

EXPOSE 80