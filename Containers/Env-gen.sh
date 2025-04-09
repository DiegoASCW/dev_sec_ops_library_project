#!/bin/bash

# Reset do ambiente
docker stop ubuntu_apache mysql_stable > /dev/null
docker rm ubuntu_apache mysql_stable > /dev/null
#docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 php:8.2-apache > /dev/null
docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 > /dev/null
docker volume rm mysql-data  > /dev/null

# Passo 1: Criar as redes Docker
echo -e "\nCriando a rede Docker..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5



# "===============[APACHE]==============="
# Passo 2: Criar diretórios para volumes
echo -e "\nCriando diretórios para volumes..."
mkdir -p html
touch php.ini

# Passo 3: Rodar o container do Apache com PHP
echo -e "\nRodando o container Apache/PHP..."

docker run -d \
  --name ubuntu_apache \
  -p 80:80 \
  --network apache_network-R5  \
  --ip 10.0.5.10 \
  -v $(pwd)/php.ini:/usr/local/etc/php/conf.d/custom.ini \
  -v $(pwd)/../Projeto_Web/Online-Library-Management-System-PHP-master:/var/www/html\
  php:8.2-apache \
  bash -c "docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground"

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache


echo -e "\nAmbiente Docker Apache/PHP criado com sucesso!"

# Criar arquivo de teste PHP
echo -e "<?php phpinfo(); ?>" > html/info.php




# "===============[MySQL]==============="

# Passo 2: Criar o volume Docker para persistir os dados do MySQL
echo -e "\nCriando o volume Docker..."
docker volume create mysql-data

# Passo 3: Rodar o container do MySQL
echo -e "\nRodando o container MySQL..."

docker pull diegolautenscs/personal_stables:mysql-openshelf-v3

docker run -d \
  --name mysql_stable \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  --network mysql_network-R4 \
  --ip 10.0.4.10 \
  -e MYSQL_ROOT_PASSWORD=passwd \
  -e MYSQL_DATABASE=openshelf_schema \
  -e MYSQL_USER=Admin \
  -e MYSQL_PASSWORD=passwd \
  diegolautenscs/personal_stables:mysql-openshelf-v3

docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable

echo -e "\nAmbiente Docker MySQL criado com sucesso!\n"



echo -e "\n\n\n===============[APACHE]==============="

echo -e "\n\n INFORMAÇÕES DO CONTAINER:"
echo -e "Servidor Apache com PHP 8.2 instalado"
echo -e "Extensões incluídas: pdo_mysql"
echo -e "Módulo Apache habilitado: rewrite"

echo -e "\n\n Para acessar o container:"
echo "docker exec -it ubuntu_apache bash"

echo -e "\n\n Para testar o PHP:"
echo "Acesse no navegador: http://localhost/info.php"

echo -e "\n\n Detalhes de rede:"
echo "Nome: apache_network-R5"
echo "Gateway: 10.0.5.254"
echo "IP-range: 10.0.5.0/24"
echo "Container IP: 10.0.5.10"

echo -e "\n\n Volumes mapeados:"
echo "Projeto Web: $(pwd)../Projeto_Web/Online-Library-Management-System-PHP-master/library → /var/www/html"
echo "PHP.ini: $(pwd)/php.ini → /usr/local/etc/php/conf.d/custom.ini"



echo -e "\n\n\n===============[MySQL]==============="

echo -e "\n\n CREDENCIAIS DO DOCKER:\nuser: root\nPassword: passwd"

echo -e "\n\n Para acessar o docker:\ndocker start mysql_stable\ndocker exec -it mysql_stable mysql -u root -p"

echo -e "\n\n Detalhes de rede:\nNome: mysql_network-R4\nGateway:10.0.4.254\nip-range: 10.0.4.0/24\nContainer IP: 10.0.4.11"
