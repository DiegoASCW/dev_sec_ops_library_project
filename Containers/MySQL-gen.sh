#!/bin/bash

# Passo 1: Criar a rede Docker
echo "Criando a rede Docker..."
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 openshelf_mysql_network-R4

# Passo 2: Criar o volume Docker para persistir os dados do MySQL
echo "Criando o volume Docker..."
docker volume create mysql-data

# Passo 3: Rodar o container do MySQL
echo "Rodando o container MySQL..."

docker pull diegolautenscs/personal_stables:mysql-openshelf-v3

docker run -d \
  --name mysql-stable \
  -v mysql_data:/var/lib/mysql \
  -p 3306:3306 \
  --network openshelf_mysql_network-R4 \
  --ip 10.0.4.11 \
  -e MYSQL_ROOT_PASSWORD=passwd \
  -e MYSQL_DATABASE=openshelf_schema \
  -e MYSQL_USER=Admin \
  -e MYSQL_PASSWORD=passwd \
  diegolautenscs/personal_stables:mysql-openshelf-v3

echo "Ambiente Docker MySQL criado com sucesso!"

echo -e "\n\n\n\n CREDENCIAIS DO DOCKER:\nuser: root\nPassword: passwd"

echo -e "\n\n\n\n Para acessar o docker:\ndocker start mysql-stable\ndocker exec -it mysql-stable mysql -u root -p"

echo -e "\n\n\n\n Detalhes de rede:\nNome: openshelf_mysql_network-R4\nGateway:10.0.4.254\nip-range: 10.0.4.0/24\nContainer IP: 10.0.4.11"
