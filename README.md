# dev_sec_ops_library_project

## MySQL setup
1. Execute o script em "Containers > MySQL-gen"

## Web Application Instalation
1. Baixe e descompacte o arquivo "Online-Library-Management-System-PHP-master.zip";

2. Inicie o XAMPP:
   2.1 Linux: /opt/lampp/xampp start;
   2.1 Windows: utilize o GUI.

3. Abra o arquivo de geração do Banco de Dados em "sql file/library.sql":
   3.1 Adicione no início do arquivo:
   create database library;
   use library;

5. Importe o esquema .sql:
   4.1 Acesse a URL: https://127.0.0.1/phpmyadmin/
   4.2 No painel à esquerda (em baixo da logo do PHPMyAdmin), selecione "New";
   4.3 No painel superior, selecione "Import";
   4.4 Selecione o arquivo no caminho: "sql file/library.sql".

6. Pronto! Agora pode acessar o projeto web. Mas ATENÇÃO, no banco de dados, foi alterado a database de "library" -> "openshelf", por isso algumas alterações podem ser necessárias por enquanto. 
 
