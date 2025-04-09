# Passo 1: Criar a rede Docker
Write-Host "Criando a rede Docker..."
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 openshelf_mysql_network-R4

# Passo 2: Criar o volume Docker para persistência dos dados do MySQL
Write-Host "Criando o volume Docker..."
docker volume create mysql-data

# Passo 3: Rodar o container do MySQL
Write-Host "Rodando o container MySQL..."
docker pull diegolautenscs/personal_stables:mysql-openshelf-v3

docker run -d --name mysql-stable -v mysql_data:/var/lib/mysql -p 3306:3306 --network openshelf_mysql_network-R4 --ip 10.0.4.11 -e MYSQL_ROOT_PASSWORD=passwd -e MYSQL_DATABASE=openshelf_schema -e MYSQL_USER=Admin -e MYSQL_PASSWORD=passwd diegolautenscs/personal_stables:mysql-openshelf-v3

Write-Host "Ambiente Docker MySQL e Banco de Dados criados e populados com sucesso!"

Write-Host "\n\n\n\nCREDENCIAIS DO DOCKER:\nuser: root\nPassword: passwd"

Write-Host "Para acessar o Docker:\ndocker start mysql-stable\ndocker exec -it mysql-stable mysql -u root -p"

Write-Host "Detalhes de rede:\nNome: openshelf_mysql_network-R4\nGateway: 10.0.4.254\nip-range: 10.0.4.0/24\nContainer IP: 10.0.4.11"
