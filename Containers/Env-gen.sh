#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# ANSI color codes
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
NC="\e[0m"  # No Color

# -----------------------------
# 1. Check if Docker is installed
# -----------------------------
if ! command -v docker &> /dev/null; then
  echo -e "${RED}ERROR${NC}: Docker is not installed."
  exit 1
fi

# -----------------------------
# 2. Check if Docker is running
# -----------------------------
if ! docker info &> /dev/null; then
  echo -e "${RED}ERROR${NC}: Docker is not running."
  exit 1
fi

# -----------------------------
# 3. Environment cleaning
# -----------------------------
read -rp $'\nDo you want to clean the environment (recommended before redeploying)? [y/N] ' escolha
if [[ "$escolha" == "y" ]]; then
  echo -e "${BLUE}INFO${NC}: removing containers, networks, volumes for 'Openshelf' project..."
  docker stop ubuntu_apache mysql_stable -t 0 &> /dev/null || true
  docker rm ubuntu_apache mysql_stable mysql-stable &> /dev/null || true
  # Uncomment and adjust images as needed:
  # docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 \ 
  #   diegolautenscs/web_sec_stables:mysql-openshelf-v12 mysql-openshelf-v12 php:8.2-apache -f &> /dev/null || true
  docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 openshelf_mysql_network-R4 &> /dev/null || true
  docker volume rm mysql-data -f &> /dev/null || true
  echo -e "${BLUE}INFO${NC}: environment cleaning finished!"
fi

# -----------------------------
# 4. Check port availability
# -----------------------------
function check_port() {
  local port=$1
  if ss -ltn | grep -q ":${port} "; then
    echo -e "\n${RED}ERROR${NC}: Port ${port} is already in use."
    echo "Troubleshoot with: ss -ltn | grep ':${port} '"
    echo "Also check Docker containers: docker ps"
    exit 1
  fi
}

check_port 3306
check_port 80

# -----------------------------
# 5. Create Docker networks
# -----------------------------
echo -e "\n${BLUE}INFO${NC}: creating Docker networks..."

echo -e "\n${BLUE}INFO${NC}: creating mysql_network-R5 (10.0.5.0/24)..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5

echo -e "\n${BLUE}INFO${NC}: creating mysql_network-R4 (10.0.4.0/24)..."
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4

echo -e "\n${BLUE}INFO${NC}: creating apache_mysql_network-R4-5 (10.0.45.0/24)..."
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

# -----------------------------
# 6. Apache/PHP container setup
# -----------------------------
echo -e "\n${BLUE}INFO${NC}: deploying Apache/PHP container..."
# Convert current path for volume mount
PWD_UNIX="${PWD//\\//}"

docker run -d \
  --name ubuntu_apache \
  -p 80:80 \
  --network apache_network-R5 \
  --ip 10.0.5.10 \
  -v "${PWD_UNIX}/../Projeto_Web/site:/var/www/html" \
  php:8.2-apache \
  bash -c 'docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground'

docker cp ./captcha_dependencies.sh ubuntu_apache:/tmp
sleep 10

echo -e "\n${BLUE}INFO${NC}: installing GD dependencies in 'ubuntu_apache' container..."
docker exec -i ubuntu_apache bash "/tmp/captcha_dependencies.sh" &> /dev/null

docker restart ubuntu_apache

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache

echo -e "\n${BLUE}INFO${NC}: Apache/PHP environment created successfully!"

# -----------------------------
# 7. MySQL container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: creating Docker volume 'mysql-data'..."
docker volume create mysql-data &> /dev/null

echo -e "\n${BLUE}INFO${NC}: pulling and deploying MySQL container..."
docker pull mysql:latest

docker run -d \
  --name mysql_stable \
  -v mysql-data:/var/lib/mysql \
  -p 3306:3306 \
  --network mysql_network-R4 \
  --ip 10.0.4.10 \
  -e MYSQL_ROOT_PASSWORD=passwd \
  mysql:latest

docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable

echo -e "\n${BLUE}INFO${NC}: creating 'openshelf' database..."
docker exec -i mysql_stable mysql -u root -ppasswd -e "CREATE DATABASE IF NOT EXISTS openshelf;"

sleep 15

docker exec -i mysql_stable mysql -u root -ppasswd -e "SHOW DATABASES;"

echo -e "\n${YELLOW}WARN${NC}: loading schema and sample data..."
# Load schema and sample data
cat << 'EOSQL' | docker exec -i mysql_stable mysql -u root -ppasswd
CREATE USER 'admin'@'%' IDENTIFIED BY 'passwd';
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%';
USE openshelf;

-- Schema definitions
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

-- Sample data
INSERT INTO tblauthors (id, AuthorName, creationDate, UpdationDate) VALUES
  (1,'Machado de Assis','2010-03-12 09:15:00','2012-07-20 14:22:30'),
  (2,'Clarice Lispector','2011-05-25 10:45:12','2015-11-03 16:40:50'),
  (3,'Jorge Amado','2009-09-18 08:30:00','2013-04-15 13:55:20'),
  (4,'Cecília Meireles','2012-01-05 17:10:45','2015-11-03 16:40:50'),
  (5,'Carlos Drummond de Andrade','2013-08-21 11:12:00','2015-11-03 16:40:50'),
  (6,'Rubem Fonseca','2016-02-14 14:48:30','2019-10-09 12:37:10');
INSERT INTO tblbooks (id,CatId,CommentId,PublisherId,BookName,Description,QuantityTotal,QuantityLeft,AuthorId,ISBNNumber,BookPrice,RegDate,UpdationDate) VALUES
  (1,1,0,1,'Dom Casmurro','A classic novel by Machado de Assis',100,95,1,9788563560452,25.00,'2011-05-10 14:32:21','2013-03-15 10:20:30'),
  (2,2,0,2,'A Hora da Estrela','A timeless novel by Clarice Lispector',80,75,2,9788535914849,22.00,'2012-08-17 09:14:55','2014-06-11 16:45:00'),
  (3,3,0,3,'Capitães da Areia','Fascinating narrative by Jorge Amado',90,85,3,9788520932072,28.00,'2010-11-05 12:00:00','2015-01-25 17:30:12'),
  (4,4,0,4,'Romanceiro da Inconfidência','Historical narrative by Cecília Meireles',70,65,4,9788535907926,19.00,'2013-04-18 08:40:22','2017-07-15 05:54:41'),
  (5,4,0,5,'Alguma Poesia','A collection of poems by Carlos Drummond de Andrade',50,50,5,9788572326972,24.00,'2014-06-30 11:10:50','2017-07-15 05:54:41'),
  (6,5,0,6,'Agosto','A captivating story by Rubem Fonseca',120,110,6,9788535932287,30.00,'2016-09-14 10:00:00','2018-12-01 13:45:10'),
  (7,1,0,1,'Memórias Póstumas de Brás Cubas','A satirical classic by Machado de Assis',100,90,1,9788535910667,26.00,'2010-02-20 15:00:00','2012-11-04 09:25:35'),
  (8,2,0,2,'Laços de Família','A family saga by Clarice Lispector',85,80,2,9788535914849,21.00,'2011-10-01 13:20:00','2014-03-12 08:18:00'),
  (9,3,0,3,'Gabriela, Cravo e Canela','A warm tale by Jorge Amado',95,90,3,9788520932096,27.00,'2009-07-22 17:10:00','2013-07-08 16:09:40'),
  (10,4,0,4,'Poemas Escritos na Índia','Poems by Cecília Meireles',60,55,4,9788571106896,18.00,'2012-12-12 18:30:30','2017-07-15 05:54:41');
INSERT INTO tblcategory (id,CategoryName,Status,CreationDate,UpdationDate) VALUES
  (1,'Romance Clássico',1,'2010-01-15 10:20:00','2012-06-10 14:45:00'),
  (2,'Literatura Contemporânea',1,'2011-03-22 11:30:00','2014-09-18 16:00:00'),
  (3,'Literatura Regionalista',1,'2009-07-10 09:50:00','2013-01-12 12:10:00'),
  (4,'Poesia Brasileira',1,'2012-04-28 08:15:00','2015-05-25 17:00:00'),
  (5,'Romance Policial',1,'2016-01-20 13:30:00','2019-10-01 09:40:00'),
  (6,'Ensaios Literários',1,'2012-10-05 15:45:00','2019-10-01 09:40:00');
INSERT INTO tblstudents (id,StudentId,FullName,EmailId,MobileNumber,Password,Status,RegDate,UpdationDate) VALUES
  (1,'SID002','Lucas Oliveira','lucas.oliveira@gmail.com','9865472555','698dc19d489c4e4db73e28a713eab07b',1,'2017-07-11 15:37:05','2017-07-15 18:26:21'),
  (4,'SID005','Beatriz Silva','beatriz.silva@gmail.com','8569710025','698dc19d489c4e4db73e28a713eab07b',0,'2017-07-11 15:41:27','2017-07-15 17:43:03'),
  (8,'SID009','Carlos Eduardo','carlos.edu@gmail.com','2359874527','698dc19d489c4e4db73e28a713eab07b',1,'2017-07-11 15:58:28','2017-07-15 13:42:44'),
  (9,'SID010','Fernanda Rocha','fernanda.rocha@gmail.com','8585856224','698dc19d489c4e4db73e28a713eab07b',1,'2017-07-15 13:40:30','2017-07-15 13:42:44'),
  (10,'SID011','Rafael Souza','rafael.souza@gmail.com','4672423754','698dc19d489c4e4db73e28a713eab07b',1,'2017-07-15 18:00:59','2017-07-15 13:42:44');
INSERT INTO tblissuedbookdetails (id,BookId,StudentID,IssuesDate,ReturnDate,RetrunStatus,fine) VALUES
  (1,1,'SID002','2017-07-15 06:09:47','2017-07-15 11:15:20',1,0),
  (2,1,'SID002','2017-07-15 06:12:27','2017-07-15 11:15:23',1,5),
  (3,3,'SID002','2017-07-15 06:13:40',NULL,0,NULL),
  (4,3,'SID002','2017-07-15 06:23:23','2017-07-15 11:22:29',1,2),
  (5,1,'SID009','2017-07-15 10:59:26',NULL,0,NULL),
  (6,3,'SID011','2017-07-15 18:02:55',NULL,0,NULL);
INSERT INTO tblstudents (StudentId,FullName,EmailId,MobileNumber,Password,Status) VALUES('STD007','teste','teste@gmail.com','123','698dc19d489c4e4db73e28a713eab07b',1);
INSERT INTO admin (FullName,AdminEmail,UserName,Password) VALUES('teste','teste@gmail.com','teste','698dc19d489c4e4db73e28a713eab07b');
EOSQL

echo -e "\n${BLUE}Setup complete!${NC}"

echo -e "\n\n\n==============[APACHE]=============="
echo -e "\nCONTAINER INFORMATION:"
echo "- Apache server with PHP 8.2 installed"
echo "- Included extension: pdo_mysql"
echo "- Enabled Apache module: rewrite"
echo -e "\nTo access the container: docker exec -it ubuntu_apache bash"
echo -e "\nTo check Apache logs: docker exec -it ubuntu_apache bash -c 'tail -f /var/log/apache2/error.log'"
echo -e "\nTest PHP at: http://localhost/library"

echo -e "\n\n\n===============[MySQL]==============="
echo -e "\nCREDENTIALS:\n  user: root\n  password: passwd"
echo -e "\nAccess MySQL: docker exec -it mysql_stable mysql -u root -p"
echo -e "\nNetwork details:\n  Name: mysql_network-R4\n  Gateway: 10.0.4.254\n  Subnet: 10.0.4.0/24\n  Container IP: 10.0.4.10"
