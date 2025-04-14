#!/bin/bash

# Verifica se o Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker não está instalado."
    exit 1
fi

# Verifica se o serviço do Docker está ativo
if systemctl is-active --quiet docker; then
    echo ""
else
    echo "Docker NÃO está rodando."
    exit 1
fi

# Reset do ambiente
read -p "Deseja realizar a limpeza total do ambiente (y/N)?" escolha

if [ "$escolha" == "y" ]; then
  docker stop ubuntu_apache mysql_stable > /dev/null
  docker rm ubuntu_apache mysql_stable mysql-stable > /dev/null
  docker rmi diegolautenscs/web_sec_stables:mysql-openshelf-v12 diegolautenscs/web_sec_stables:mysql-openshelf-v12 mysql-openshelf-v12 mysql php:8.2-apache > /dev/null
  docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 openshelf_mysql_network-R4 > /dev/null
  docker volume rm mysql-data  > /dev/null
fi

# Verificar se a porta 3306 está sendo usada e avisa o usuário
if lsof -i TCP:3306 -sTCP:LISTEN >/dev/null 2>&1; then
    echo -e "A porta 3306 já está sendo usada. Verifique se o MySQL ou outro serviço está rodando. Excute:\nlsof -i -P -n | grep 3306"
    exit 1
fi

if lsof -i TCP:80 -sTCP:LISTEN >/dev/null 2>&1; then
    echo -e "A porta 80 já está sendo usada. Verifique se o MySQL ou outro serviço está rodando. Excute:\nlsof -i -P -n | grep 3306"
    exit 1
fi



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
  -v $(pwd)/../Projeto_Web/site:/var/www/html\
  php:8.2-apache \
  bash -c "docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground"

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache

docker cp ./captcha_dependencies.sh ubuntu_apache:/tmp

Start-Sleep -Seconds 10

docker exec -i ubuntu_apache bash "/tmp/captcha_dependencies.sh"

docker restart ubuntu_apache

echo -e "\nAmbiente Docker Apache/PHP criado com sucesso!"



# "===============[MySQL]==============="

# Passo 2: Criar o volume Docker para persistir os dados do MySQL
echo -e "\nCriando o volume Docker..."
docker volume create mysql-data

# Passo 3: Rodar o container do MySQL
echo -e "\nRodando o container MySQL..."

docker pull mysql

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
  mysql

docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable

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

docker exec -i mysql_stable mysql -u root -ppasswd -e "USE openshelf;INSERT INTO tblstudents (StudentId, FullName, EmailId, MobileNumber, Password, Status) VALUES ('STD007', 'teste', 'teste@gmail.com', '123', '698dc19d489c4e4db73e28a713eab07b', 1);"

docker exec -it mysql_stable mysql -u root -ppasswd -e "USE openshelf;INSERT INTO admin (FullName, AdminEmail, UserName, Password) VALUES ('teste', 'teste@gmail.com', 'teste', '698dc19d489c4e4db73e28a713eab07b');"

echo -e "\nAmbiente Docker MySQL criado com sucesso!\n"



echo -e "\n\n\n===============[APACHE]==============="

echo -e "\n\n INFORMAÇÕES DO CONTAINER:"
echo -e "Servidor Apache com PHP 8.2 instalado"
echo -e "Extensões incluídas: pdo_mysql"
echo -e "Módulo Apache habilitado: rewrite"

echo -e "\n\n Para acessar o container:"
echo "docker exec -it ubuntu_apache bash"

echo -e "\n\n Para testar o PHP:"
echo "Acesse no navegador: http://localhost/library"

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
