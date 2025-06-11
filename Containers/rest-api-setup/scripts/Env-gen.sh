#!/usr/bin/env bash

set -euo pipefail

# ANSI color codes
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
NC="\e[0m"  # No Color


# -----------------------------
# 6. Apache/PHP container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of Apache 8.2 'ubuntu_apache' container..."

echo -e "\n${BLUE}INFO${NC}: deploying Apache/PHP container..."
PWD_UNIX="${PWD//\\//}"

docker build -t apache_openshelf_image -f ../docker/apache/apache.dockerfile ../../..

# -----------------------------
# 7. MySQL container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of MySQL 8.0 'mysql_stable' container..."

echo -e "\n${BLUE}INFO${NC}: creating Docker volume 'mysql-data'..."

echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"
docker build -t mysql_openshelf_image -f ../docker/sql/mysql.dockerfile ../docker/sql/

# -----------------------------
# 8. API Gateway container setup
# -----------------------------
echo -e "\n\n\n${BLUE}INFO${NC}: starting the creation of Debian 12 'debian_api_gateway' container..."

echo -e "\n${BLUE}INFO${NC}: creating Docker volume 'audit_logs'..."

echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"
docker build --platform=linux/amd64 -t debian_api_gateway_openshelf_image -f ../docker/api_gateway/api_gateway.dockerfile ../docker/api_gateway


# -----------------------------
# 9. Micro Auth
# -----------------------------
echo -e "\n${BLUE}INFO${NC}: starting the creation of Debian 12 'micro_auth_api' container..."

echo -e "\n${BLUE}INFO${NC}: preparing enviroment and installing dependencies"

docker build --platform=linux/amd64 -t micro_auth_openshelf_image -f ../docker/micro-auth/auth.dockerfile ../docker/micro-auth


# -----------------------------
# 10. Micro List Reg Books
# -----------------------------

docker build --platform=linux/amd64 -t micro-list_reg_books_openshelf_image -f ../docker/micro-list-reg-books/list_reg.dockerfile ../docker/micro-list-reg-books



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
