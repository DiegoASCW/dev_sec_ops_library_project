# Usa a imagem oficial do PHP com Apache
FROM php:8.2-apache

# --- INÍCIO DAS MODIFICAÇÕES ---

# 1. Instala dependências do sistema necessárias para o Composer (git, unzip)
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# 2. Instala o Composer globalmente dentro da imagem
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 3. Define o diretório de trabalho para a pasta do site
#    Isso garante que os comandos seguintes rodem no lugar certo
WORKDIR /var/www/html/library

# 4. Copia apenas os arquivos do Composer para aproveitar o cache do Docker
#    Certifique-se que os arquivos composer.json e composer.lock existem em Projeto_Web/site/library
COPY ./Projeto_Web/site/library/composer.json .
COPY ./Projeto_Web/site/library/composer.lock .

# 5. Roda o 'composer install' para criar a pasta vendor/ com o SDK da AWS
#    --no-dev é uma boa prática para não instalar dependências de desenvolvimento
RUN composer install --no-dev --no-interaction --no-plugins --no-scripts --prefer-dist

# 6. Volta para o diretório raiz para os próximos comandos COPY funcionarem como antes
WORKDIR /var/www/html

# --- FIM DAS MODIFICAÇÕES ---

# Copia todo o código do site (isso vai sobrescrever o composer.json/lock mas a pasta vendor/ já existe)
COPY ./Projeto_Web/site /var/www/html

# Copia e executa seu script de dependências do captcha (isso continua igual)
COPY ./Containers/rest-api-setup/docker/apache/captcha_dependencies.sh /tmp
RUN bash /tmp/captcha_dependencies.sh

# Instalando dependências e habilitando SSL (isso continua igual)
RUN apt update && \
    apt install -y apache2 openssl && \
    a2enmod ssl

# Criando certificado autoassinado (isso continua igual)
RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/apache-selfsigned.key \
    -out /etc/ssl/certs/apache-selfsigned.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=Openshelf/CN=openshelf.local"

# Configurando Apache com SSL e redirecionamento (isso continua igual)
RUN cat <<EOF > /etc/apache2/sites-available/000-default.conf
<VirtualHost *:443> 
    ServerName localhost 
    DocumentRoot /var/www/html 

    PassEnv COGNITO_REGION
    PassEnv COGNITO_CLIENT_ID
    PassEnv COGNITO_USER_POOL_ID
    PassEnv COGNITO_CLIENT_SECRET

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

# Expondo as portas HTTP e HTTPS (isso continua igual)
EXPOSE 80
EXPOSE 443