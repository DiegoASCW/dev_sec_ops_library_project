# Verifica se o Docker está instalado
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "Docker não está instalado."
    exit 1
}

docker info > $null
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
} else {
    Write-Host "Docker NÃO está rodando."
}


# Reset do ambiente
$escolha = Read-Host "Deseja realizar a limpeza total do ambiente (y/N)?"

if ($escolha -eq "y") {
    docker stop ubuntu_apache mysql_stable | Out-Null
    docker rm ubuntu_apache mysql_stable mysql-stable | Out-Null
    docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 diegolautenscs/web_sec_stables:mysql-openshelf-v12 mysql-openshelf-v12 mysql php:8.2-apache | Out-Null
    docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 openshelf_mysql_network-R4 | Out-Null
    docker volume rm mysql-data | Out-Null
}

# Verificar se a porta 3306 está sendo usada
$porta3306 = Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue
if ($porta3306) {
    Write-Host "A porta 3306 já está sendo usada. Verifique se o MySQL ou outro serviço está rodando. Execute:"
    Write-Host "Get-NetTCPConnection -LocalPort 3306 | Format-Table"
    Write-Host "Veja também se há outro container mysql sendo executado"
    Write-Host "docker ps"
    exit 1
}

# Verificar se a porta 80 está sendo usada
$porta80 = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
if ($porta80) {
    Write-Host "A porta 80 já está sendo usada. Verifique se o Apache ou outro serviço está rodando. Execute:"
    Write-Host "Get-NetTCPConnection -LocalPort 80 | Format-Table"
    Write-Host "Veja também se há outro container apache ou php sendo executado"
    Write-Host "docker ps"
    exit 1
}


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
docker pull mysql

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
  mysql

docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable

Start-Sleep -Seconds 10

docker exec -i mysql_stable mysql -u root -ppasswd -e "
CREATE DATABASE openshelf;
USE openshelf;

CREATE TABLE admin (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100),
    AdminEmail VARCHAR(120),
    UserName VARCHAR(100) NOT NULL,
    Password VARCHAR(100) NOT NULL,
    updationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblauthors (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    AuthorName VARCHAR(159),
    creationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UpdationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblbooks (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    CatId INT,
    CommentId INT,
    PublisherId INT,
    BookName VARCHAR(255),
    Description VARCHAR(255),
    QuantityTotal INT NOT NULL,
    QuantityLeft INT NOT NULL,
    AuthorId INT,
    ISBNNumber BIGINT,
    BookPrice DECIMAL(10,2),
    RegDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UpdationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblcategory (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(150),
    Status INT,
    CreationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UpdationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblcomment (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    UserId INT NOT NULL,
    Comment VARCHAR(255) NOT NULL,
    CreationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tblhelpdesk (
    id INT NOT NULL PRIMARY KEY,
    FullName VARCHAR(100),
    HelpDeskEmail VARCHAR(120),
    UserName VARCHAR(100) NOT NULL,
    Password VARCHAR(100) NOT NULL,
    updationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblissuedbookdetails (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    BookId INT,
    StudentID VARCHAR(150),
    IssuesDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    ReturnDate TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    ReturnStatus INT,
    fine INT
);

CREATE TABLE tblpublisher (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    CNPJ VARCHAR(20) NOT NULL UNIQUE,
    CreationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tblstudents (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    StudentId VARCHAR(100) UNIQUE,
    FullName VARCHAR(120),
    EmailId VARCHAR(120),
    MobileNumber CHAR(11),
    Password VARCHAR(120),
    Status INT,
    RegDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UpdationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblworkers (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    WorkerEmail VARCHAR(120) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Username VARCHAR(255) NOT NULL UNIQUE,
    UpdationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FullName VARCHAR(255) NOT NULL,
    Role VARCHAR(100) NOT NULL
);
"

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
Write-Host "Open in your browser: http://localhost/library"
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
