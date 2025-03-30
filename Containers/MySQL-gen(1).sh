#!/bin/bash

# Passo 1: Criar a rede Docker
echo "Criando a rede Docker..."
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 openshelf_mysql_network-R4

# Passo 2: Criar o volume Docker para persistir os dados do MySQL
echo "Criando o volume Docker..."
docker volume create mysql-data

# Passo 3: Rodar o container do MySQL
echo "Rodando o container MySQL..."
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
  mysql

# Aguardar o container MySQL iniciar
echo "Aguardando o MySQL iniciar..."
sleep 15

# Passo 4: Criar a database openshelf
echo "Criando a database 'openshelf'..."
docker exec -i mysql-stable mysql -u root -ppasswd -e "CREATE DATABASE IF NOT EXISTS openshelf;"

# Passo 5: Criar as tabelas usando as queries que você me passou
echo "Criando as tabelas..."
docker exec -i mysql-stable mysql -u root -ppasswd openshelf < <(cat <<-EOF
  -- Tabelas
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

  CREATE TABLE IF NOT EXISTS Funcionario (
      id_funcionario INT PRIMARY KEY AUTO_INCREMENT,
      id_endereco INT NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      senha VARCHAR(255) NOT NULL,
      nome_usuario VARCHAR(100) UNIQUE NOT NULL,
      quando_entrou DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      nome_completo VARCHAR(255) NOT NULL,
      funcao VARCHAR(100) NOT NULL,
      FOREIGN KEY (id_endereco) REFERENCES Endereco(id_endereco) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS SuporteTecnico (
      id_suporte_tecnico INT PRIMARY KEY AUTO_INCREMENT,
      id_cliente INT NOT NULL,
      id_endereco INT NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      senha VARCHAR(255) NOT NULL,
      nome_usuario VARCHAR(100) UNIQUE NOT NULL,
      quando_entrou DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      nome_completo VARCHAR(255) NOT NULL,
      FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE CASCADE,
      FOREIGN KEY (id_endereco) REFERENCES Endereco(id_endereco) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS Administrador (
      id_administrador INT PRIMARY KEY AUTO_INCREMENT,
      id_cliente INT NOT NULL,
      id_endereco INT NOT NULL,
      email VARCHAR(255) UNIQUE NOT NULL,
      senha VARCHAR(255) NOT NULL,
      nome_usuario VARCHAR(100) UNIQUE NOT NULL,
      quando_entrou DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      nome_completo VARCHAR(255) NOT NULL,
      FOREIGN KEY (id_cliente) REFERENCES Cliente(id_cliente) ON DELETE CASCADE,
      FOREIGN KEY (id_endereco) REFERENCES Endereco(id_endereco) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS Editora (
      id_editora INT PRIMARY KEY AUTO_INCREMENT,
      nome VARCHAR(255) NOT NULL,
      cnpj VARCHAR(20) UNIQUE NOT NULL,
      estado VARCHAR(50) NOT NULL,
      cep VARCHAR(20) NOT NULL,
      quando_entrou DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL
  );

  CREATE TABLE IF NOT EXISTS Livro (
      id_livro INT PRIMARY KEY AUTO_INCREMENT,
      id_editora INT NOT NULL,
      titulo VARCHAR(255) NOT NULL,
      descricao TEXT NOT NULL,
      quantidade_total INT NOT NULL,
      quantidade_disponivel INT NOT NULL,
      quando_entrou DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      FOREIGN KEY (id_editora) REFERENCES Editora(id_editora) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS Reserva (
      id_reserva INT PRIMARY KEY AUTO_INCREMENT,
      id_usuario INT NOT NULL,
      id_livro INT NOT NULL,
      data_inicio DATE NOT NULL,
      data_fim DATE NOT NULL,
      cancelado BOOLEAN DEFAULT FALSE NOT NULL,
      FOREIGN KEY (id_usuario) REFERENCES Cliente(id_cliente) ON DELETE CASCADE,
      FOREIGN KEY (id_livro) REFERENCES Livro(id_livro) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS Comentario (
      id_comentario INT PRIMARY KEY AUTO_INCREMENT,
      id_usuario INT NOT NULL,
      id_livro INT NOT NULL,
      titulo VARCHAR(255) NOT NULL,
      comentario TEXT NOT NULL,
      data_escrita DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      FOREIGN KEY (id_usuario) REFERENCES Cliente(id_cliente) ON DELETE CASCADE,
      FOREIGN KEY (id_livro) REFERENCES Livro(id_livro) ON DELETE CASCADE
  );

  CREATE TABLE IF NOT EXISTS Auditoria (
      id_auditoria INT PRIMARY KEY AUTO_INCREMENT,
      id_usuario INT NOT NULL,
      acao VARCHAR(255) NOT NULL,
      detalhes TEXT NOT NULL,
      data_hora DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
      FOREIGN KEY (id_usuario) REFERENCES Cliente(id_cliente) ON DELETE CASCADE
  );
EOF
)

# Passo 6: Inserir dados na tabela
echo "Inserindo dados nas tabelas..."
docker exec -i mysql-stable mysql -u root -ppasswd openshelf < <(cat <<-EOF
  INSERT INTO Endereco (endereco_residencial, cidade, estado, cep, pais) VALUES
  ('Rua das Flores, 123', 'São Paulo', 'SP', '01000-000', 'Brasil'),
  ('Avenida Brasil, 456', 'Rio de Janeiro', 'RJ', '20000-000', 'Brasil'),
  ('Rua Principal, 789', 'Belo Horizonte', 'MG', '30000-000', 'Brasil');

  INSERT INTO Cliente (id_endereco, email, senha, nome_usuario, nome_completo) VALUES
  (1, 'joao.silva@email.com', 'senha123', 'joao.silva', 'João Silva'),
  (2, 'ana.pereira@email.com', 'senha456', 'ana.pereira', 'Ana Pereira'),
  (3, 'luiz.santos@email.com', 'senha789', 'luiz.santos', 'Luiz Santos');

  INSERT INTO Funcionario (id_endereco, email, senha, nome_usuario, nome_completo, funcao) VALUES
  (1, 'marcos.funcionario@email.com', 'senha111', 'marcos.funcionario', 'Marcos Oliveira', 'Vendedor'),
  (2, 'patricia.funcionario@email.com', 'senha222', 'patricia.funcionario', 'Patricia Souza', 'Suporte Técnico'),
  (3, 'rogerio.funcionario@email.com', 'senha333', 'rogerio.funcionario', 'Rogério Costa', 'Administrador');

  INSERT INTO Editora (nome, cnpj, estado, cep) VALUES
  ('Editora ABC', '12.345.678/0001-90', 'SP', '01010-000'),
  ('Editora XYZ', '98.765.432/0001-01', 'RJ', '20010-000'),
  ('Editora Nova', '11.223.344/0001-11', 'MG', '30010-000');

  INSERT INTO Livro (id_editora, titulo, descricao, quantidade_total, quantidade_disponivel) VALUES
  (1, 'O Poder do Hábito', 'Livro sobre formação de hábitos', 50, 30),
  (2, 'A Arte da Guerra', 'Estratégias militares clássicas', 40, 25),
  (3, 'O Pequeno Príncipe', 'História infantil famosa', 100, 60);
EOF
)

echo "Ambiente Docker MySQL e Banco de Dados criados e populados com sucesso!"

echo -e "\n\n\n\n CREDENCIAIS DO DOCKER:\nuser: root\nPassword: passwd"

echo -e "\n\n\n\n Para acessar o docker:\ndocker start mysql-stable\ndocker exec -it mysql-stable mysql -u root -p"

echo -e "\n\n\n\n Detalhes de rede:\nNome: openshelf_mysql_network-R4\nGateway:10.0.4.254\nip-range: 10.0.4.0/24\nContainer IP: 10.0.4.11"
