#!/bin/bash

# Passo 1: Criar a rede Docker
echo "Criando a rede Docker..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5

# Passo 2: Criar diretórios para volumes
echo "Criando diretórios para volumes..."
mkdir -p html
touch php.ini

# Passo 3: Rodar o container do Apache com PHP
echo "Rodando o container Apache/PHP..."

docker run -d \
  --name ubuntu_apache \
  -p 80:80 \
  --network apache_network-R5 \
  --ip 10.0.5.10 \
  -v $(pwd)/html:/var/www/html \
  -v $(pwd)/php.ini:/usr/local/etc/php/conf.d/custom.ini \
  php:8.2-apache \
  bash -c "docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground"

echo "Ambiente Docker Apache/PHP criado com sucesso!"

# Criar arquivo de teste PHP
echo "<?php phpinfo(); ?>" > html/info.php

echo -e "\n\n\n\n INFORMAÇÕES DO CONTAINER:"
echo -e "Servidor Apache com PHP 8.2 instalado"
echo -e "Extensões incluídas: pdo_mysql"
echo -e "Módulo Apache habilitado: rewrite"

echo -e "\n\n\n\n Para acessar o container:"
echo "docker exec -it ubuntu_apache bash"

echo -e "\n\n\n\n Para testar o PHP:"
echo "Acesse no navegador: http://localhost/info.php"

echo -e "\n\n\n\n Detalhes de rede:"
echo "Nome: apache_network-R5"
echo "Gateway: 10.0.5.254"
echo "IP-range: 10.0.5.0/24"
echo "Container IP: 10.0.5.10"

echo -e "\n\n\n\n Volumes mapeados:"
echo "HTML: $(pwd)/html → /var/www/html"
echo "PHP.ini: $(pwd)/php.ini → /usr/local/etc/php/conf.d/custom.ini"
