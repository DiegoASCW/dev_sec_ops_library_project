# Reset the environment
docker stop ubuntu_apache mysql_stable | Out-Null
docker rm ubuntu_apache mysql_stable | Out-Null
# docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 php:8.2-apache | Out-Null
docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 | Out-Null
docker volume rm mysql-data | Out-Null

# Step 1: Create Docker networks
Write-Host "`nCreating Docker networks..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

# ===============[APACHE]===============
# Step 2: Create directories for volumes
Write-Host "`nCreating directories for volumes..."
New-Item -Path html -ItemType Directory -Force | Out-Null
New-Item -Path php.ini -ItemType File -Force | Out-Null

# Step 3: Run the Apache/PHP container
Write-Host "`nRunning Apache/PHP container..."

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

Write-Host "`nDocker Apache/PHP environment created successfully!"

# Create a PHP test file
Write-Host "`nCreating PHP test file..."
Set-Content -Path "html/info.php" -Value "<?php phpinfo(); ?>"

# ===============[MYSQL]===============
# Step 2: Create the Docker volume for MySQL data persistence
Write-Host "`nCreating Docker volume..."
docker volume create mysql-data | Out-Null

# Step 3: Run the MySQL container
Write-Host "`nRunning MySQL container..."
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

Write-Host "`nDocker MySQL environment created successfully!`n"

# Information Output for Apache Container
Write-Host "`n`n`n==============[APACHE]=============="
Write-Host "`n`nCONTAINER INFORMATION:"
Write-Host "Apache server with PHP 8.2 installed"
Write-Host "Included extension: pdo_mysql"
Write-Host "Enabled Apache module: rewrite"
Write-Host "`n`nTo access the container:"
Write-Host "docker exec -it ubuntu_apache bash"
Write-Host "`n`nTo test PHP:"
Write-Host "Open in your browser: http://localhost/info.php"
Write-Host "`n`nNetwork details:"
Write-Host "Name: apache_network-R5"
Write-Host "Gateway: 10.0.5.254"
Write-Host "IP range: 10.0.5.0/24"
Write-Host "Container IP: 10.0.5.10"
Write-Host "`n`nMapped volumes:"
Write-Host "Web Project: $pwdUnix/../Projeto_Web/Online-Library-Management-System-PHP-master/library → /var/www/html"
Write-Host "PHP.ini: $pwdUnix/php.ini → /usr/local/etc/php/conf.d/custom.ini"

# Information Output for MySQL Container
Write-Host "`n`n`n==============[MYSQL]=============="
Write-Host "`n`nDOCKER CREDENTIALS:`nuser: root`nPassword: passwd"
Write-Host "`n`nTo access the container:"
Write-Host "docker start mysql_stable"
Write-Host "docker exec -it mysql_stable mysql -u root -p"
Write-Host "`n`nNetwork details:"
Write-Host "Name: mysql_network-R4"
Write-Host "Gateway: 10.0.4.254"
Write-Host "IP range: 10.0.4.0/24"
Write-Host "Container IP: 10.0.4.11"
