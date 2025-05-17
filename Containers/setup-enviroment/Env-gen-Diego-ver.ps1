# Check if 'Docker' in installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host ": Docker is not installed." 
    exit 1
}

# Check if 'Docker' is running
docker info > $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host ": Docker is not running."
    exit 1
}

# Enviroment cleaning
$escolha = Read-Host "`nDo you want to clean the enviroment (recomended in case of redeploy the infraestructure)?  [y/N] "

if ($escolha -eq "y") {
  Write-Host "INFO" -ForegroundColor Blue -NoNewline
  Write-Host ": removing containers, networks, volumes, and images, about 'Openshelf' project"

  docker stop ubuntu_apache mysql_stable -t 0 *> $null
  docker rm ubuntu_apache mysql_stable mysql-stable *> $null
  #docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 diegolautenscs/web_sec_stables:mysql-openshelf-v12 mysql-openshelf-v12 mysql php:8.2-apache -f *> $null
  docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 openshelf_mysql_network-R4 backup_mysql_network-R94 *> $null
  docker volume rm mysql-data -f *> $null

  Write-Host "INFO" -ForegroundColor Blue -NoNewline
  Write-Host ": enviroment cleaning finished!"
}

# Check the availability for port 3306
$porta3306 = Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue
if ($porta3306) {
    Write-Host "`nERROR" -ForegroundColor Red -NoNewline
    Write-Host ": the port 3306 is already in using by another application. Please, verify if MySQL or another service is running in 3306 port. Run for troubleshoot:"
    Write-Host "Get-NetTCPConnection -LocalPort 3306 | Format-Table"
    Write-Host "See also if another Docker container is using the port 3306:"
    Write-Host "docker ps"
    exit 1
}

# Check the availability for port 80
$porta80 = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
if ($porta80) {
    Write-Host "`nERROR: the port 80 is already in using by another application. Please, verify if Apache or another service is running in 3306 port. Run for troubleshoot:"
    Write-Host "Get-NetTCPConnection -LocalPort 80 | Format-Table"
    Write-Host "See also if another Docker container is using the port 80:"
    Write-Host "docker ps"
    exit 1
}

# Step 1: Create Docker networks
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker networks"

Write-Host "Network 'apache_network-R5' (ip-range: 10.0.5.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5 

Write-Host "`nNetwork 'mysql_network-R4' (ip-range: 10.0.4.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4

Write-Host "`nNetwork 'apache_mysql_network-R4-5' (ip-range: 10.0.45.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

Write-Host "`nNetwork 'backup_mysql_network-R94' (ip-range: 10.0.94.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.94.0/24 --ip-range=10.0.94.0/24 --gateway=10.0.94.254 backup_mysql_network-R94


# ===============[APACHE]===============
# Step 2: Run the Apache/PHP container
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Apache/PHP container..."

# Convert the current working directory to a Unix-friendly path (replace backslashes with forward slashes)
$pwdUnix = ($PWD.Path -replace "\\", "/")

docker run -d `
  --name ubuntu_apache `
  -p 80:80 `
  --network apache_network-R5 `
  --ip 10.0.5.10 `
  -v "$pwdUnix/../../Projeto_Web/site:/var/www/html" `
  php:8.2-apache `
  bash -c 'docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground'

docker cp ./captcha_dependencies.sh ubuntu_apache:/tmp

Start-Sleep -Seconds 10

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": installing dependencies for Apache2 'GD' into 'ubuntu_apache' container..."
docker exec -i ubuntu_apache bash "/tmp/captcha_dependencies.sh" | out-null

docker restart ubuntu_apache

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": docker Apache/PHP environment created successfully!"

# ===============[MYSQL]===============
# Step 2: Create the Docker volume for MySQL data persistence
Write-Host "`n`n`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker volume 'mysql-data'"
docker volume create mysql-data | Out-Null

# Step 3: Run the MySQL container
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating MySQL container"
docker pull mysql

docker run -d `
  --name mysql_stable `
  -v mysql-data:/var/lib/mysql `
  -p 3306:3306 `
  -e MYSQL_ROOT_PASSWORD=passwd `
  mysql

docker network connect --ip 10.0.4.10 mysql_network-R4 mysql_stable
docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable
docker network connect --ip 10.0.94.11 backup_mysql_network-R94 mysql_stable

Write-Host "`n`n`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": waiting for 'mysqld' service start..."

$teste = $true

while ($teste) {
    try {
        docker exec mysql_stable mysql -u root -ppasswd -e "SHOW SCHEMAS;" > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Start-Sleep -Seconds 5
            $teste = $false
        } else {
            Start-Sleep -Seconds 1
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}


docker exec -i mysql_stable mysql -u root -ppasswd -e "CREATE DATABASE openshelf;"

Write-Host "`n`n`nWARN" -ForegroundColor Yellow -NoNewline
Write-Host ": check if the database 'openshelf' is underneath:"
docker exec -i mysql_stable mysql -u root -ppasswd -e "SHOW DATABASES;"
Write-Host "`n"


Start-Sleep -Seconds 5 

$CreateTablesQuery = @'
CREATE USER 'admin'@'%' IDENTIFIED BY 'passwd';

GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';

USE openshelf;

CREATE TABLE admin (
    id INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100),
    AdminEmail VARCHAR(120),
    UserName VARCHAR(100) NOT NULL,
    Password VARCHAR(100) NOT NULL,
    updationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblauthors (
    id INT AUTO_INCREMENT PRIMARY KEY,
    AuthorName VARCHAR(159),
    creationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UpdationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblbooks (
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
    CategoryName VARCHAR(150),
    Status INT,
    CreationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    UpdationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblcomment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Userid INT,
    Comment VARCHAR(255) NOT NULL,
    CreationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tblhelpdesk (
    id INT AUTO_INCREMENT PRIMARY KEY,
    FullName VARCHAR(100),
    HelpDeskEmail VARCHAR(120),
    UserName VARCHAR(100) NOT NULL,
    Password VARCHAR(100) NOT NULL,
    updationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE tblissuedbookdetails (
    id INT AUTO_INCREMENT PRIMARY KEY,
    BookId INT,
    StudentID VARCHAR(150),
    IssuesDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    ReturnDate TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    RetrunStatus INT,
    fine INT
);

CREATE TABLE tblpublisher (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    CNPJ VARCHAR(20) NOT NULL UNIQUE,
    CreationDate TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE tblstudents (
    id INT AUTO_INCREMENT PRIMARY KEY,
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
    id INT AUTO_INCREMENT PRIMARY KEY,
    WorkerEmail VARCHAR(120) NOT NULL UNIQUE,
    Password VARCHAR(255) NOT NULL,
    Username VARCHAR(255) NOT NULL UNIQUE,
    UpdationDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FullName VARCHAR(255) NOT NULL,
    Role VARCHAR(100) NOT NULL
);
'@

$InsertSample = @'
USE openshelf;

INSERT INTO 
tblauthors (id, AuthorName, creationDate, UpdationDate) 
VALUES
  (1, 'Machado de Assis', '2010-03-12 09:15:00', '2012-07-20 14:22:30'),
  (2, 'Clarice Lispector', '2011-05-25 10:45:12', '2015-11-03 16:40:50'),
  (3, 'Jorge Amado', '2009-09-18 08:30:00', '2013-04-15 13:55:20'),
  (4, 'Cecília Meireles', '2012-01-05 17:10:45', '2015-11-03 16:40:50'),
  (5, 'Carlos Drummond de Andrade', '2013-08-21 11:12:00', '2015-11-03 16:40:50'),
  (6, 'Rubem Fonseca', '2016-02-14 14:48:30', '2019-10-09 12:37:10');

INSERT INTO 
  tblbooks (id, CatId, CommentId, PublisherId, BookName, Description, QuantityTotal, QuantityLeft, AuthorId, ISBNNumber, BookPrice, RegDate, UpdationDate)
VALUES
  (1, 1, 0, 1, 'Dom Casmurro', 'A classic novel by Machado de Assis', 100, 95, 1, 9788563560452, 25.00, '2011-05-10 14:32:21', '2013-03-15 10:20:30'),
  (2, 2, 0, 2, 'A Hora da Estrela', 'A timeless novel by Clarice Lispector', 80, 75, 2, 9788535914849, 22.00, '2012-08-17 09:14:55', '2014-06-11 16:45:00'),
  (3, 3, 0, 3, 'Capitães da Areia', 'Fascinating narrative by Jorge Amado', 90, 85, 3, 9788520932072, 28.00, '2010-11-05 12:00:00', '2015-01-25 17:30:12'),
  (4, 4, 0, 4, 'Romanceiro da Inconfidência', 'Historical narrative by Cecília Meireles', 70, 65, 4, 9788535907926, 19.00, '2013-04-18 08:40:22', '2017-07-15 05:54:41'),
  (5, 4, 0, 5, 'Alguma Poesia', 'A collection of poems by Carlos Drummond de Andrade', 50, 50, 5, 9788572326972, 24.00, '2014-06-30 11:10:50', '2017-07-15 05:54:41'),
  (6, 5, 0, 6, 'Agosto', 'A captivating story by Rubem Fonseca', 120, 110, 6, 9788535932287, 30.00, '2016-09-14 10:00:00', '2018-12-01 13:45:10'),
  (7, 1, 0, 1, 'Memórias Póstumas de Brás Cubas', 'A satirical classic by Machado de Assis', 100, 90, 1, 9788535910667, 26.00, '2010-02-20 15:00:00', '2012-11-04 09:25:35'),
  (8, 2, 0, 2, 'Laços de Família', 'A family saga by Clarice Lispector', 85, 80, 2, 9788535914849, 21.00, '2011-10-01 13:20:00', '2014-03-12 08:18:00'),
  (9, 3, 0, 3, 'Gabriela, Cravo e Canela', 'A warm tale by Jorge Amado', 95, 90, 3, 9788520932096, 27.00, '2009-07-22 17:10:00', '2013-07-08 16:09:40'),
  (10, 4, 0, 4, 'Poemas Escritos na Índia', 'Poems by Cecília Meireles', 60, 55, 4, 9788571106896, 18.00, '2012-12-12 18:30:30', '2017-07-15 05:54:41');


INSERT INTO 
  tblcategory (id, CategoryName, Status, CreationDate, UpdationDate)
VALUES
  (1, 'Romance Clássico', 1, '2010-01-15 10:20:00', '2012-06-10 14:45:00'),
  (2, 'Literatura Contemporânea', 1, '2011-03-22 11:30:00', '2014-09-18 16:00:00'),
  (3, 'Literatura Regionalista', 1, '2009-07-10 09:50:00', '2013-01-12 12:10:00'),
  (4, 'Poesia Brasileira', 1, '2012-04-28 08:15:00', '2015-05-25 17:00:00'),
  (5, 'Romance Policial', 1, '2016-01-20 13:30:00', '2019-10-01 09:40:00'),
  (6, 'Ensaios Literários', 1, '2012-10-05 15:45:00', '2019-10-01 09:40:00');

INSERT INTO 
  tblstudents (id, StudentId, FullName, EmailId, MobileNumber, Password, Status, RegDate, UpdationDate)
VALUES
  (1, 'SID002', 'Lucas Oliveira', 'lucas.oliveira@gmail.com', '9865472555', '698dc19d489c4e4db73e28a713eab07b', 1, '2017-07-11 15:37:05', '2017-07-15 18:26:21'),
  (4, 'SID005', 'Beatriz Silva', 'beatriz.silva@gmail.com', '8569710025', '698dc19d489c4e4db73e28a713eab07b', 0, '2017-07-11 15:41:27', '2017-07-15 17:43:03'),
  (8, 'SID009', 'Carlos Eduardo', 'carlos.edu@gmail.com', '2359874527', '698dc19d489c4e4db73e28a713eab07b', 1, '2017-07-11 15:58:28', '2017-07-15 13:42:44'),
  (9, 'SID010', 'Fernanda Rocha', 'fernanda.rocha@gmail.com', '8585856224', '698dc19d489c4e4db73e28a713eab07b', 1, '2017-07-15 13:40:30', '2017-07-15 13:42:44'),
  (10, 'SID011', 'Rafael Souza', 'rafael.souza@gmail.com', '4672423754', '698dc19d489c4e4db73e28a713eab07b', 1, '2017-07-15 18:00:59', '2017-07-15 13:42:44');


INSERT INTO 
  tblissuedbookdetails (id, BookId, StudentID, IssuesDate, ReturnDate, RetrunStatus, fine)
VALUES
  (1, 1, 'SID002', '2017-07-15 06:09:47', '2017-07-15 11:15:20', 1, 0),
  (2, 1, 'SID002', '2017-07-15 06:12:27', '2017-07-15 11:15:23', 1, 5),
  (3, 3, 'SID002', '2017-07-15 06:13:40', NULL, 0, NULL),
  (4, 3, 'SID002', '2017-07-15 06:23:23', '2017-07-15 11:22:29', 1, 2),
  (5, 1, 'SID009', '2017-07-15 10:59:26', NULL, 0, NULL),
  (6, 3, 'SID011', '2017-07-15 18:02:55', NULL, 0, NULL);

INSERT INTO tblstudents (StudentId, FullName, EmailId, MobileNumber, Password, Status) VALUES ('STD007', 'teste', 'teste@gmail.com', '123', '698dc19d489c4e4db73e28a713eab07b', 1);
INSERT INTO admin (FullName, AdminEmail, UserName, Password) VALUES ('teste', 'teste@gmail.com', 'teste', '698dc19d489c4e4db73e28a713eab07b');
'@

$CreateTablesQuery | docker exec -i mysql_stable mysql -u root -ppasswd
$InsertSample | docker exec -i mysql_stable mysql -u root -ppasswd

Write-Host "`n`n`n==============[APACHE]=============="
Write-Host "`n`nCONTAINER INFORMATION:"
Write-Host "Apache server with PHP 8.2 installed"
Write-Host "Included extension: pdo_mysql"
Write-Host "Enabled Apache module: rewrite"
Write-Host "`n`nTo access the container:"
Write-Host "docker exec -it ubuntu_apache bash"
Write-Host "`n`nTo check Apache Error Logs:"
Write-Host "docker exec -it ubuntu_apache bash -c 'tail -f /var/log/apache2/error.log'"
Write-Host "`n`nTo test PHP:"
Write-Host "Open in your browser: http://localhost/library"
Write-Host "`n"

Write-Host "`n`n`n===============[MySQL]==============="
Write-Host "`n`nCREDENCIAIS DO DOCKER:`nuser: root`nPassword: passwd"
Write-Host "`n`nPara acessar o docker:`ndocker start mysql_stable`ndocker exec -it mysql_stable mysql -u root -p"
Write-Host "`n`nDetalhes de rede:`nNome: mysql_network-R4`nGateway:10.0.4.254`nip-range: 10.0.4.0/24`nContainer IP: 10.0.4.11`n`n"
