FROM mysql:8.0

# copia o script sql
# script sql é executado automaticamente, vide ref: https://hub.docker.com/_/mysql
COPY openshelf-setup.sql /docker-entrypoint-initdb.d/

# Exponha a porta do MySQL
EXPOSE 3306
