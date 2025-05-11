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
read -rp $' (1) Make Backup\n (2) Put Backup on prod\n=' escolha

# -----------------------------
# 3. Environment cleaning
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
      debian:12 \
      bash -c "cp -R /mnt/mysql/* /mnt/backup/"

    docker stop backup_mysql &> /dev/null || true
    docker rm backup_mysql &> /dev/null || true  
    
    echo -e "\n\n\n${BLUE}INFO${NC}: backup volume 'backup-mysql-data-$date' created"
fi


