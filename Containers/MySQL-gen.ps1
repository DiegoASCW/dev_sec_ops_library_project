# Passo 1: Criar a rede Docker
Write-Host "Criando a rede Docker..."
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 openshelf_mysql_network-R4

# Passo 2: Criar o volume Docker para persistência dos dados do MySQL
Write-Host "Criando o volume Docker..."
docker volume create mysql-data

# Passo 3: Rodar o container do MySQL
Write-Host "Rodando o container MySQL..."
docker run -d --name mysql-stable -v mysql_data:/var/lib/mysql -p 3306:3306 --network openshelf_mysql_network-R4 --ip 10.0.4.11 -e MYSQL_ROOT_PASSWORD=passwd -e MYSQL_DATABASE=openshelf_schema -e MYSQL_USER=Admin -e MYSQL_PASSWORD=passwd mysql

# Aguardar o container MySQL iniciar
Write-Host "Aguardando o MySQL iniciar..."
Start-Sleep -Seconds 15

# Passo 4: Criar a database openshelf
Write-Host "Criando a database 'openshelf'..."
docker exec -i mysql-stable mysql -u root -ppasswd -e "CREATE DATABASE IF NOT EXISTS openshelf;"

# Passo 5: Criar as tabelas
Write-Host "Criando as tabelas..."
$sqlTables = @"
  CREATE TABLE IF NOT EXISTS Endereco (
      id_endereco INT PRIMARY KEY AUTO_INCREMENT,
      endereco_residencial VARCHAR(255) NOT NULL,
      cidade VARCHAR(100) NOT NULL,
      estado VARCHAR(50) NOT NULL,
      cep VARCHAR(20) NOT NULL,
      pais VARCHAR(100) NOT NULL
  );
  
  CREATE TABLE IF NOT EXISTS Cliente (
      id_cliente INT PRIMARY KEY AUTO_INCREMENT,
      id_endereco INT NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      senha VARCHAR(255) NOT NULL,
      nome_usuario VARCHAR(100) UNIQUE NOT NULL,
      quando_entrou DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      nome_completo VARCHAR(255) NOT NULL,
      FOREIGN KEY (id_endereco) REFERENCES Endereco(id_endereco) ON DELETE CASCADE
  );
"@
$sqlTables | docker exec -i mysql-stable mysql -u root -ppasswd openshelf

# Passo 6: Inserir dados nas tabelas
Write-Host "Inserindo dados nas tabelas..."
$sqlInserts = @"
  INSERT INTO Endereco (endereco_residencial, cidade, estado, cep, pais) VALUES
  ('Rua das Flores, 123', 'São Paulo', 'SP', '01000-000', 'Brasil'),
  ('Avenida Brasil, 456', 'Rio de Janeiro', 'RJ', '20000-000', 'Brasil'),
  ('Rua Principal, 789', 'Belo Horizonte', 'MG', '30000-000', 'Brasil');
  
  INSERT INTO Cliente (id_endereco, email, senha, nome_usuario, nome_completo) VALUES
  (1, 'joao.silva@email.com', 'senha123', 'joao.silva', 'João Silva'),
  (2, 'ana.pereira@email.com', 'senha456', 'ana.pereira', 'Ana Pereira'),
  (3, 'luiz.santos@email.com', 'senha789', 'luiz.santos', 'Luiz Santos');
"@
$sqlInserts | docker exec -i mysql-stable mysql -u root -ppasswd openshelf

Write-Host "Ambiente Docker MySQL e Banco de Dados criados e populados com sucesso!"

Write-Host "\n\n\n\nCREDENCIAIS DO DOCKER:\nuser: root\nPassword: passwd"

Write-Host "Para acessar o Docker:\ndocker start mysql-stable\ndocker exec -it mysql-stable mysql -u root -p"

Write-Host "Detalhes de rede:\nNome: openshelf_mysql_network-R4\nGateway: 10.0.4.254\nip-range: 10.0.4.0/24\nContainer IP: 10.0.4.11"
