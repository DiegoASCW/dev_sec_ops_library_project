#!/bin/bash

# libera o uso do apt
chmod 1777 /tmp

# instala pacotes python necessários para instalar as libs python abaixo
apt update && apt upgrade -y && apt install -y python3 python3.11-venv default-libmysqlclient-dev build-essential python3-dev

source venv/bin/activate

pip install pymysql flask authlib requests
