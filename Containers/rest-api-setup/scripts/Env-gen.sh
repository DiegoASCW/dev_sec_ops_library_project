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
  docker stop ubuntu_apache mysql_stable debian_api_gateway micro_auth_api -t 0 &> /dev/null || true
  docker rm ubuntu_apache mysql_stable mysql-stable debian_api_gateway micro_auth_api &> /dev/null || true
  docker rmi debian_api_gateway_openshelf_image mysql_stable_image apache_openshelf_image micro_auth_openshelf_image -f &> /dev/null || true
  docker network rm apache_network-R5 mysql_network-R4 \
      apache_mysql_network-R4-5 openshelf_mysql_network-R4 \
      backup_mysql_network-R94 backup_mysql_network-R75 \
      backup_mysql_network-R74 micro_auth_network_R1001 &> /dev/null || true

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

echo -e "\n${BLUE}INFO${NC}: creating apache_network-R5 (10.0.5.0/24)..."
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5

echo -e "\n${BLUE}INFO${NC}: creating mysql_network-R4 (10.0.4.0/24)..."
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4

echo -e "\n${BLUE}INFO${NC}: creating apache_mysql_network-R4-5 (10.0.45.0/24)..."
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

# backup
echo -e "\n${BLUE}INFO${NC}: creating backup_mysql_network-R94 (10.0.94.0/24)..."
docker network create --driver bridge --subnet=10.0.94.0/24 --ip-range=10.0.94.0/24 --gateway=10.0.94.254 backup_mysql_network-R94

# REST API
## API_GATEWAY <> Apache
echo -e "\n${BLUE}INFO${NC}: creating backup_mysql_network-R75 (10.0.75.0/24)..."
docker network create --driver bridge --subnet=10.0.75.0/24 --ip-range=10.0.75.0/24 --gateway=10.0.75.254 backup_mysql_network-R75

## API_GATEWAY <> Micro-Auth
echo -e "\n${BLUE}INFO${NC}: creating micro_auth_network_R1001 (10.100.1.0/24)..."
docker network create --driver bridge --subnet=10.100.1.0/24 --ip-range=10.100.1.0/24 --gateway=10.100.1.254 micro_auth_network_R1001

## Micro-Auth <> MySQL
echo -e "\n${BLUE}INFO${NC}: creating micro_auth_mysql_network-R10014 (10.100.4.0/24)..."
docker network create --driver bridge --subnet=10.100.4.0/24 --ip-range=10.100.4.0/24 --gateway=10.100.4.254 micro_auth_mysql_network-R10014


# -----------------------------
# 6. Apache/PHP container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of Apache 8.2 'ubuntu_apache' container..."

echo -e "\n${BLUE}INFO${NC}: deploying Apache/PHP container..."
PWD_UNIX="${PWD//\\//}"

docker build -t apache_openshelf_image -f ../docker/apache/apache.dockerfile ../docker/apache
docker create --name ubuntu_apache -p 80:80 -v "${PWD_UNIX}/../../../Projeto_Web/site:/var/www/html" apache_openshelf_image

docker network connect --ip 10.0.5.10 apache_network-R5 ubuntu_apache
docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache
docker network connect --ip 10.0.75.11 backup_mysql_network-R75 ubuntu_apache

docker start ubuntu_apache

echo -e "\n${BLUE}INFO${NC}: Apache/PHP environment created successfully!"


# -----------------------------
# 7. MySQL container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of MySQL 8.0 'mysql_stable' container..."

echo -e "\n${BLUE}INFO${NC}: creating Docker volume 'mysql-data'..."
docker volume create mysql-data &> /dev/null

echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"
docker build -t mysql_openshelf_image -f ../docker/sql/mysql.dockerfile ../docker/sql/
docker create --name mysql_stable -p 3306:3306 -e MYSQL_ROOT_PASSWORD=passwd -v mysql-data:/var/lib/mysql mysql_openshelf_image

docker network connect --ip 10.0.4.10 mysql_network-R4 mysql_stable
docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable
docker network connect --ip 10.0.94.11 backup_mysql_network-R94 mysql_stable
docker network connect --ip 10.100.4.10 micro_auth_mysql_network-R10014 mysql_stable

docker start mysql_stable

echo -e "\n${BLUE}INFO${NC}: creating 'openshelf' database, schema and sample data..."


# -----------------------------
# 8. API Gateway container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of Debian 12 'debian_api_gateway' container..."

echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"
docker build -t debian_api_gateway_openshelf_image -f ../docker/api_gateway/api_gateway.dockerfile ../docker/api_gateway
docker create --name debian_api_gateway -p 5000:5000 debian_api_gateway_openshelf_image

docker network connect --ip 10.0.75.10 backup_mysql_network-R75 debian_api_gateway
docker network connect --ip 10.100.1.11 micro_auth_network_R1001 debian_api_gateway

echo -e "\n${BLUE}INFO${NC}: starting 'debian_api_gateway' container and API Gateway service"
docker start debian_api_gateway


# -----------------------------
# 9. Micro Auth
# -----------------------------
echo -e "\n${BLUE}INFO${NC}: starting the creation of Debian 12 'micro_auth_api' container..."

echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"

docker build --platform=linux/amd64 -t micro_auth_openshelf_image -f ../docker/micro-auth/auth.dockerfile ../docker/micro-auth
docker create --name micro_auth_api -p 5001:5001 micro_auth_openshelf_image

docker network connect --ip 10.100.1.10 micro_auth_network_R1001 micro_auth_api
docker network connect --ip 10.100.4.11 micro_auth_mysql_network-R10014 micro_auth_api

echo -e "\n${BLUE}INFO${NC}: starting 'micro_auth_api' container and API Gateway service"
docker start micro_auth_api

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