#!/usr/bin/env bash

date=$(date '+%Y-%m-%d')

# ANSI color codes
RED="\e[31m"
BLUE="\e[34m"
YELLOW="\e[33m"
NC="\e[0m"

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

echo -e '\n-----------------------------\nWelcome to Openshelf Backup Center!\n-----------------------------'
read -rp $' (1) Make Backup\n (2) Put Backup on prod\n\n=' escolha


# -----------------------------
# 3. Make Backup
# -----------------------------
if [[ "$escolha" -eq "1" ]]; then
    echo -e "\n\n\n${YELLOW}WARN${NC}: 'Make Backup' option selected"
    docker volume create backup-mysql-data-$date &> /dev/null

    docker run -d \
      --name backup_mysql \
      -v mysql-data:/mnt/mysql \
      -v backup-mysql-data-$date:/mnt/backup \
      --network backup_mysql_network-R94 \
      --ip 10.0.94.10 \
      mysql:latest \
      bash -c "mysqldump -h 10.0.94.11 -u root -ppasswd --databases openshelf > /mnt/backup/mysql-backup.sql"

    docker stop backup_mysql &> /dev/null || true
    docker rm backup_mysql &> /dev/null || true  
    
    echo -e "\n${BLUE}INFO${NC}: backup volume 'backup-mysql-data-$date' created"

  # -----------------------------
  # 4. Replace 'mysql-data' data to backup-mysql-data-$date
  # -----------------------------
  elif [[ "$escolha" -eq "2" ]]; then
    echo -e "\n${YELLOW}WARN${NC}: 'Make Backup' option selected"
    readarray -t array_docker_volume < <(docker volume ls -q | grep "backup-mysql-data")

    # Shows and choose a backup volume
    echo -e "\nSelecione algum backup de volume para adicionar em produção:"
    for volume_index in "${!array_docker_volume[@]}"
    do
      echo "($volume_index) - ${array_docker_volume[$volume_index]}"
    done
    read -rp $'\n=' escolha

    # Start the prod replace to backup
    echo -e "\n${YELLOW}WARN${NC}: Replacing actual MySQL data to '${array_docker_volume[$escolha]}'"
    
    docker exec -i mysql_stable mysql -u root -ppasswd -e "DROP DATABASE openshelf; CREATE DATABASE openshelf;"

    docker run -d \
      --name backup_mysql \
      -v mysql-data:/mnt/mysql \
      -v ${array_docker_volume[$escolha]}:/mnt/backup \
      --network backup_mysql_network-R94 \
      --ip 10.0.94.10 \
      mysql:latest \
      bash -c "mysql -h 10.0.94.11  -u root -ppasswd openshelf < /mnt/backup/mysql-backup.sql"

    docker stop backup_mysql &> /dev/null || true
    docker rm backup_mysql &> /dev/null || true
    
    echo -e "\n${BLUE}INFO${NC}: volume substitution concluded!"
fi