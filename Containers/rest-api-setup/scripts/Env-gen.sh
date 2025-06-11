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

  docker stop ubuntu_apache mysql_stable debian_api_gateway micro_auth_api micro_list_reg_books_api register_list_auth_api -t 0 &> /dev/null || true
  docker rm ubuntu_apache mysql_stable mysql-stable debian_api_gateway micro_auth_api micro_list_reg_books_api register_list_auth_api &> /dev/null || true
  docker rmi debian_api_gateway_openshelf_image mysql_stable_image apache_openshelf_image micro_auth_openshelf_image micro-list_reg_books_openshelf_image register-list-auth_openshelf_image -f &> /dev/null || true

  docker network rm apache_network-R5 mysql_network-R4 \
    apache_mysql_network-R4-5 openshelf_mysql_network-R4 \
    backup_mysql_network-R94 backup_mysql_network-R75 \
    backup_mysql_network-R74 micro_auth_network_R1001 \
    api_gateway_apache_network-R1015 micro_auth_mysql_network-R10014 \
    micro_list_reg_books_network_R1002 micro_list_reg_books_mysql_network-R10024 \
    micro_register_list_auth_network_R1003 micro_register_list_auth_mysql_network-R10034 &> /dev/null || true

  docker volume rm mysql-data audit_logs -f &> /dev/null || true
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

docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5
docker network create --driver bridge --subnet=10.0.94.0/24 --ip-range=10.0.94.0/24 --gateway=10.0.94.254 backup_mysql_network-R94
docker network create --driver bridge --subnet=10.101.0.0/24 --ip-range=10.101.0.0/24 --gateway=10.101.0.254 api_gateway_apache_network-R1015
docker network create --driver bridge --subnet=10.100.1.0/24 --ip-range=10.100.1.0/24 --gateway=10.100.1.254 micro_auth_network_R1001
docker network create --driver bridge --subnet=10.100.14.0/24 --ip-range=10.100.14.0/24 --gateway=10.100.14.254 micro_auth_mysql_network-R10014
docker network create --driver bridge --subnet=10.100.2.0/24 --ip-range=10.100.2.0/24 --gateway=10.100.2.254 micro_list_reg_books_network_R1002
docker network create --driver bridge --subnet=10.100.24.0/24 --ip-range=10.100.24.0/24 --gateway=10.100.24.254 micro_list_reg_books_mysql_network-R10024
docker network create --driver bridge --subnet=10.100.3.0/24 --ip-range=10.100.3.0/24 --gateway=10.100.3.254 micro_register_list_auth_network_R1003
docker network create --driver bridge --subnet=10.100.34.0/24 --ip-range=10.100.34.0/24 --gateway=10.100.34.254 micro_register_list_auth_mysql_network-R10034

# -----------------------------
# 6. Apache/PHP container setup
# -----------------------------
echo -e "\n\n${BLUE}INFO${NC}: creating Apache 8.2 'ubuntu_apache' container..."
docker build -t apache_openshelf_image -f ../docker/apache/apache.dockerfile ../../..
docker create --name ubuntu_apache -p 80:80 apache_openshelf_image
docker network connect --ip 10.0.5.10 apache_network-R5 ubuntu_apache
docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache
docker network connect --ip 10.101.0.11 api_gateway_apache_network-R1015 ubuntu_apache
docker start ubuntu_apache

# -----------------------------
# 7. MySQL container setup
# -----------------------------
echo -e "\n\n${BLUE}INFO${NC}: creating MySQL 8.0 'mysql_stable' container..."
docker volume create mysql-data &> /dev/null
docker build -t mysql_openshelf_image -f ../docker/sql/mysql.dockerfile ../docker/sql/
docker create --name mysql_stable -p 3306:3306 -e MYSQL_ROOT_PASSWORD=passwd -v mysql-data:/var/lib/mysql mysql_openshelf_image
docker network connect --ip 10.0.4.10 mysql_network-R4 mysql_stable
docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable
docker network connect --ip 10.0.94.11 backup_mysql_network-R94 mysql_stable
docker network connect --ip 10.100.14.10 micro_auth_mysql_network-R10014 mysql_stable
docker network connect --ip 10.100.24.10 micro_list_reg_books_mysql_network-R10024 mysql_stable
docker network connect --ip 10.100.34.11 micro_register_list_auth_mysql_network-R10034 mysql_stable
docker start mysql_stable

# -----------------------------
# 8. API Gateway container setup
# -----------------------------
docker volume create audit_logs &> /dev/null
docker build -t debian_api_gateway_openshelf_image -f ../docker/api_gateway/api_gateway.dockerfile ../docker/api_gateway
docker create --name debian_api_gateway -p 5000:5000 -v audit_logs:/var/log/audit_log debian_api_gateway_openshelf_image
docker network connect --ip 10.101.0.10 api_gateway_apache_network-R1015 debian_api_gateway
docker network connect --ip 10.100.1.11 micro_auth_network_R1001 debian_api_gateway
docker network connect --ip 10.100.2.11 micro_list_reg_books_network_R1002 debian_api_gateway
docker network connect --ip 10.100.3.11 micro_register_list_auth_network_R1003 debian_api_gateway
docker start debian_api_gateway
docker exec -i debian_api_gateway bash -c "touch /var/log/audit_log/openshelf_audit.log && chmod go-rwx /var/log/audit_log/openshelf_audit.log"

# -----------------------------
# 9. Micro Auth
# -----------------------------
docker build --platform=linux/amd64 -t micro_auth_openshelf_image -f ../docker/micro-auth/auth.dockerfile ../docker/micro-auth
docker create --name micro_auth_api -p 5001:5001 micro_auth_openshelf_image
docker network connect --ip 10.100.14.11 micro_auth_mysql_network-R10014 micro_auth_api
docker network connect --ip 10.100.1.10 micro_auth_network_R1001 micro_auth_api
docker start micro_auth_api

# -----------------------------
# 10. Micro List Reg Books
# -----------------------------
docker build --platform=linux/amd64 -t micro-list_reg_books_openshelf_image -f ../docker/micro-list-reg-books/list_reg.dockerfile ../docker/micro-list-reg-books
docker create --name micro_list_reg_books_api -p 5002:5002 micro-list_reg_books_openshelf_image
docker network connect --ip 10.100.24.11 micro_list_reg_books_mysql_network-R10024 micro_list_reg_books_api
docker network connect --ip 10.100.2.10 micro_list_reg_books_network_R1002 micro_list_reg_books_api
docker start micro_list_reg_books_api

# -----------------------------
# 11. Micro Register List Authores
# -----------------------------
docker build --platform=linux/amd64 -t register-list-auth_openshelf_image -f ../docker/micro_register_list_auth/register_list_auth.dockerfile ../docker/micro_register_list_auth
docker create --name register_list_auth_api -p 5003:5003 register-list-auth_openshelf_image
docker network connect --ip 10.100.3.10 micro_register_list_auth_network_R1003 register_list_auth_api
docker network connect --ip 10.100.34.10 micro_register_list_auth_mysql_network-R10034 register_list_auth_api
docker start register_list_auth_api

# -----------------------------
# Final logs
# -----------------------------
echo -e "\n\n\n==============[APACHE]=============="
echo -e "\nApache server with PHP 8.2 installed"
echo "- Extension: pdo_mysql"
echo "- Apache module: rewrite"
echo -e "\nAccess: http://localhost/library"
echo "Container: docker exec -it ubuntu_apache bash"

echo -e "\n\n===============[MySQL]==============="
echo -e "user: root\npassword: passwd"
echo "Container: docker exec -it mysql_stable mysql -u root -p"

echo -e "\n\n========[Register List Auth API]========"
echo "Access: http://localhost:5003/ping"
echo "Container: docker exec -it register_list_auth_api bash"

echo -e "\n${BLUE}Setup complete!${NC}"

echo -e "\n${YELLOW}NOTE${NC}: If the Jenkins pipeline fails to execute Docker commands, make sure the 'jenkins' user is part of the 'docker' group."
echo -e "${YELLOW}TIP${NC}: Run this manually if needed:\n  sudo usermod -aG docker jenkins && sudo systemctl restart jenkins\n"