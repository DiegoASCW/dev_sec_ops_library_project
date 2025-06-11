FROM php:8.2-apache

COPY ./Projeto_Web/site /var/www/html

COPY ./Containers/rest-api-setup/docker/apache/captcha_dependencies.sh /tmp

RUN bash /tmp/captcha_dependencies.sh

# Instalando dependências
RUN apt update && \
    apt install -y apache2 openssl && \
    a2enmod ssl

# Criando certificado autoassinado
RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=Openshelf/CN=openshelf.local"

# Configurando Apache com SSL e redirecionamento de HTTP para HTTPS
RUN cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:443> 
    ServerName localhost 
    DocumentRoot /var/www/html 

    SSLEngine on 
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key

    <Directory "/var/www/html">
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:80>
    ServerName localhost
    Redirect / https://localhost
</VirtualHost> 
EOF

# Expondo as portas HTTP e HTTPS
EXPOSE 80 443
