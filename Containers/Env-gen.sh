#!/bin/bash

# Reset the environment (yo, this will wipe out your current Docker setup—double-check, fam!)
docker stop ubuntu_apache mysql_stable > /dev/null
docker rm ubuntu_apache mysql_stable mysql-stable > /dev/null
docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 php:8.2-apache > /dev/null
docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 openshelf_mysql_network-R4 > /dev/null
docker volume rm mysql-data > /dev/null

# Step 1: Create Docker networks
echo -e "\nCreating Docker networks..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

# "===============[APACHE]==============="
# Step 2: Create directories for volumes
echo -e "\nCreating directories for volumes..."
mkdir -p html
touch php.ini

# Step 3: Run the Apache/PHP container
echo -e "\nLaunching the Apache/PHP container..."

docker run -d \
  --name ubuntu_apache \
  -p 80:80 \
  --network apache_network-R5 \
  --ip 10.0.5.10 \
  -v $(pwd)/php.ini:/usr/local/etc/php/conf.d/custom.ini \
  -v $(pwd)/../Projeto_Web/site:/var/www/html \
  php:8.2-apache \
  bash -c "docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground"

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache

echo -e "\nDocker environment for Apache/PHP is lit and ready!"

# Create a PHP test file
echo -e "<?php phpinfo(); ?>" > html/info.php

# "===============[MySQL]==============="
# Step 2: Create a Docker volume to persist MySQL data
echo -e "\nCreating Docker volume..."
docker volume create mysql-data

# Step 3: Run the MySQL container
echo -e "\nLaunching the MySQL container..."

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

echo -e "\nDocker environment for MySQL is up and running!\n"

echo -e "\n\n\n===============[APACHE]==============="

echo -e "\n\n CONTAINER INFO:"
echo -e "Apache server with PHP 8.2 installed"
echo -e "Included extension: pdo_mysql"
echo -e "Enabled Apache module: rewrite"

echo -e "\n\n To access the container:"
echo "docker exec -it ubuntu_apache bash"

echo -e "\n\n To test PHP:"
echo "Open in your browser: http://localhost/info.php"

echo -e "\n\n Network details:"
echo "Name: apache_network-R5"
echo "Gateway: 10.0.5.254"
echo "IP-range: 10.0.5.0/24"
echo "Container IP: 10.0.5.10"

echo -e "\n\n Mapped volumes:"
echo "Web Project: $(pwd)/../Projeto_Web/Online-Library-Management-System-PHP-master/library → /var/www/html"
echo "PHP.ini: $(pwd)/php.ini → /usr/local/etc/php/conf.d/custom.ini"

echo -e "\n\n\n===============[MySQL]==============="

echo -e "\n\n DOCKER CREDENTIALS:\nUser: root\nPassword: passwd"

echo -e "\n\n To access the MySQL container:"
echo "docker start mysql_stable"
echo "docker exec -it mysql_stable mysql -u root -p"

echo -e "\n\n Network details:"
echo "Name: mysql_network-R4"
echo "Gateway: 10.0.4.254"
echo "IP-range: 10.0.4.0/24"
echo "Container IP: 10.0.4.11"
