#!/usr/bin/env bash

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
  docker stop ubuntu_apache mysql_stable debian_api_gateway -t 0 &> /dev/null || true
  docker rm ubuntu_apache mysql_stable mysql-stable debian_api_gateway &> /dev/null || true
  # Uncomment and adjust images as needed:
  # docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 \ 
  #   diegolautenscs/web_sec_stables:mysql-openshelf-v12 mysql-openshelf-v12 php:8.2-apache -f &> /dev/null || true
  docker network rm apache_network-R5 mysql_network-R4 \
      apache_mysql_network-R4-5 openshelf_mysql_network-R4 \
      backup_mysql_network-R94 backup_mysql_network-R75 \
      backup_mysql_network-R74 &> /dev/null || true

  docker volume rm mysql-data mysql-data -f &> /dev/null || true
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

# backup
echo -e "\n${BLUE}INFO${NC}: creating backup_mysql_network-R94 (10.0.94.0/24)..."
docker network create --driver bridge --subnet=10.0.94.0/24 --ip-range=10.0.94.0/24 --gateway=10.0.94.254 backup_mysql_network-R94

# REST API
## API <> Apache
echo -e "\n${BLUE}INFO${NC}: creating backup_mysql_network-R75 (10.0.75.0/24)..."
docker network create --driver bridge --subnet=10.0.75.0/24 --ip-range=10.0.75.0/24 --gateway=10.0.75.254 backup_mysql_network-R75

## API <> MySQL
echo -e "\n${BLUE}INFO${NC}: creating backup_mysql_network-R74 (10.0.74.0/24)..."
docker network create --driver bridge --subnet=10.0.74.0/24 --ip-range=10.0.74.0/24 --gateway=10.0.74.254 backup_mysql_network-R74

# -----------------------------
# 6. Apache/PHP container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of Apache 8.2 'ubuntu_apache' container..."

echo -e "\n${BLUE}INFO${NC}: deploying Apache/PHP container..."
# Convert current path for volume mount
PWD_UNIX="${PWD//\\//}"

docker run -d \
  --name ubuntu_apache \
  -p 80:80 \
  -v "${PWD_UNIX}/../../../Projeto_Web/site:/var/www/html" \
  php:8.2-apache \
  bash -c 'docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground'

docker cp ./captcha_dependencies.sh ubuntu_apache:/tmp
sleep 10

echo -e "\n${BLUE}INFO${NC}: installing GD dependencies in 'ubuntu_apache' container..."
docker exec -i ubuntu_apache bash "/tmp/captcha_dependencies.sh" &> /dev/null

docker restart ubuntu_apache

docker network connect --ip 10.0.5.10 apache_network-R5 ubuntu_apache
docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache
docker network connect --ip 10.0.75.11 backup_mysql_network-R75 ubuntu_apache

echo -e "\n${BLUE}INFO${NC}: Apache/PHP environment created successfully!"

# -----------------------------
# 7. MySQL container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of MySQL 9.3 'mysql_stable' container..."

echo -e "\n${BLUE}INFO${NC}: creating Docker volume 'mysql-data'..."
docker volume create mysql-data &> /dev/null

echo -e "\n${BLUE}INFO${NC}: pulling and deploying MySQL container..."
docker pull mysql:latest

docker run -d \
  --name mysql_stable \
  -v mysql-data:/var/lib/mysql \
  -p 3306:3306 \
  -e MYSQL_ROOT_PASSWORD=passwd \
  mysql:9.3

docker network connect --ip 10.0.4.10 mysql_network-R4 mysql_stable
docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable
docker network connect --ip 10.0.94.11 backup_mysql_network-R94 mysql_stable
docker network connect --ip 10.0.74.11 backup_mysql_network-R74 mysql_stable

# Verify if MySQL Container has MySQL running
echo -e "\n${BLUE}INFO${NC}: waiting for 'mysqld' service start..."
set +euo pipefail
teste=1
while [ $teste -eq 1 ];
do
	docker exec "mysql_stable" mysql -u root -ppasswd -e "SHOW SCHEMAS;" > /dev/null 2>&1

	if [ $? -eq 0 ]; then
	    sleep 5
	    teste=0
	else
	    sleep 0.5
	fi
done

echo -e "\n${BLUE}INFO${NC}: creating 'openshelf' database, schema and sample data..."

docker cp ../sql/openshelf-setup.sql mysql_stable:/tmp

docker exec -i mysql_stable mysql -u root -ppasswd -e "source /tmp/openshelf-setup.sql"


# -----------------------------
# 8. API Gateway container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of Debian 12 'debian_api_gateway' container..."

echo -e "\n${BLUE}INFO${NC}: pulling and deploying Debian container..."
docker pull debian:12

docker build -t debian_api_gateway_custom -f api_gateway.dockerfile .

#docker run -i \
#  --name debian_api_gateway \
#  -v "${PWD_UNIX}/../../REST_API:/tmp" \
#  -p 5000:5000 \
#  debian:12

#echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"

docker network connect --ip 10.0.74.10 backup_mysql_network-R74 debian_api_gateway
docker network connect --ip 10.0.75.10 backup_mysql_network-R75 debian_api_gateway

#echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"
#docker cp ./api_gateway_dependencies.sh debian_api_gateway:/tmp
#docker exec -it debian_api_gateway bash -c "/bin/bash /tmp/api_gateway_dependencies.sh"
#
#echo -e "\n${BLUE}INFO${NC}: exec REST API Server"
#docker exec -it debian_api_gateway bash -c "python3 /tmp/main.py"


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