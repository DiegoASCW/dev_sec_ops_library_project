# dev_sec_ops_library_project

1. Instalation script
   
   1.1 Windows
   
      First let's ensure your computer is allowing the executing of scripts;
   
      **`Set-ExecutionPolicy RemoteSigned`**
   
      During the enabling press A
   
      In the folder with the instalation script, with docker already installed, run as Admin your Powershell instance, as **`./Env-gen.ps1`**
   
   1.2 Linux
   
      Navigate to the folder with the file in it, with docker already installed, and run the command **`sudo ./Env-gen.sh`**
      

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
 
