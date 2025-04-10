# Reset the environment
docker stop ubuntu_apache mysql_stable | Out-Null
docker rm ubuntu_apache mysql_stable | Out-Null
# docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 php:8.2-apache | Out-Null
docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 | Out-Null
docker volume rm mysql-data | Out-Null

# Step 1: Create the Docker networks
Write-Host "`nCriando a rede Docker..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

# "===============[APACHE]==============="
# Step 2: Create directories for volumes
Write-Host "`nCriando diretórios para volumes..."
New-Item -Path html -ItemType Directory -Force | Out-Null
New-Item -Path php.ini -ItemType File -Force | Out-Null

# Step 3: Run the Apache/PHP container
Write-Host "`nRodando o container Apache/PHP..."

# Convert the current working directory to a Unix-friendly path (replace backslashes with forward slashes)
$pwdUnix = ($PWD.Path -replace "\\", "/")

docker run -d `
  --name ubuntu_apache `
  -p 80:80 `
  --network apache_network-R5 `
  --ip 10.0.5.10 `
  -v "$pwdUnix/php.ini:/usr/local/etc/php/conf.d/custom.ini" `
  -v "$pwdUnix/../Projeto_Web/site:/var/www/html" `
  php:8.2-apache `
  bash -c "docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground"

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache

Write-Host "`nAmbiente Docker Apache/PHP criado com sucesso!"

# Create a PHP test file
Write-Host "`nCriando arquivo de teste PHP..."
Set-Content -Path "html/info.php" -Value "<?php phpinfo(); ?>"

# "===============[MySQL]==============="
# Step 2: Create the Docker volume for MySQL data persistence
Write-Host "`nCriando o volume Docker..."
docker volume create mysql-data | Out-Null

# Step 3: Run the MySQL container
Write-Host "`nRodando o container MySQL..."
docker pull diegolautenscs/personal_stables:mysql-openshelf-v3

docker run -d `
  --name mysql_stable `
  -v mysql-data:/var/lib/mysql `
  -p 3306:3306 `
  --network mysql_network-R4 `
  --ip 10.0.4.10 `
  -e MYSQL_ROOT_PASSWORD=passwd `
  -e MYSQL_DATABASE=openshelf_schema `
  -e MYSQL_USER=Admin `
  -e MYSQL_PASSWORD=passwd `
  diegolautenscs/personal_stables:mysql-openshelf-v3

docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable

Write-Host "`nAmbiente Docker MySQL criado com sucesso!`n"

# Information Output for Apache Container
Write-Host "`n`n`n===============[APACHE]==============="
Write-Host "`n`nINFORMAÇÕES DO CONTAINER:"
Write-Host "Servidor Apache com PHP 8.2 instalado"
Write-Host "Extensões incluídas: pdo_mysql"
Write-Host "Módulo Apache habilitado: rewrite"
Write-Host "`n`nPara acessar o container:"
Write-Host "docker exec -it ubuntu_apache bash"
Write-Host "`n`nPara testar o PHP:"
Write-Host "Acesse no navegador: http://localhost/info.php"
Write-Host "`n`nDetalhes de rede:"
Write-Host "Nome: apache_network-R5"
Write-Host "Gateway: 10.0.5.254"
Write-Host "IP-range: 10.0.5.0/24"
Write-Host "Container IP: 10.0.5.10"
Write-Host "`n`nVolumes mapeados:"
Write-Host "Projeto Web: $pwdUnix/../Projeto_Web/Online-Library-Management-System-PHP-master/library → /var/www/html"
Write-Host "PHP.ini: $pwdUnix/php.ini → /usr/local/etc/php/conf.d/custom.ini"

# Information Output for MySQL Container
Write-Host "`n`n`n===============[MySQL]==============="
Write-Host "`n`nCREDENCIAIS DO DOCKER:`nuser: root`nPassword: passwd"
Write-Host "`n`nPara acessar o docker:"
Write-Host "docker start mysql_stable"
Write-Host "docker exec -it mysql_stable mysql -u root -p"
Write-Host "`n`nDetalhes de rede:"
Write-Host "Nome: mysql_network-R4"
Write-Host "Gateway: 10.0.4.254"
Write-Host "ip-range: 10.0.4.0/24"
Write-Host "Container IP: 10.0.4.11"
