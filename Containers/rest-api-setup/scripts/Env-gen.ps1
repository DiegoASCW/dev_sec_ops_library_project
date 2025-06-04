# -----------------------------
# 1. Check if Docker is installed
# -----------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host ": Docker is not installed." 
    exit 1
}


# -----------------------------
# 2. Check if Docker is running
# -----------------------------
docker info > $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host ": Docker is not running."
    exit 1
}


# -----------------------------
# 3. Environment cleaning
# -----------------------------
$escolha = Read-Host "`nDo you want to clean the enviroment (recomended in case of redeploy the infraestructure)?  [y/N] "

if ($escolha -eq "y") {
  Write-Host "INFO" -ForegroundColor Blue -NoNewline
  Write-Host ": removing containers, networks, volumes, and images, about 'Openshelf' project"

  docker stop ubuntu_apache mysql_stable debian_api_gateway micro-auth-api micro_auth_api micro_list_reg_books_api 0 *> $null
  docker rm ubuntu_apache mysql_stable debian_api_gateway micro-auth-api micro_auth_api micro_list_reg_books_api *> $null
  docker rmi debian_api_gateway_openshelf_image micro-auth_openshelf_image mysql_stable_image apache_openshelf_image -f *> $null
  docker network rm apache_network-R5 mysql_network-R4 `
    apache_mysql_network-R4-5 openshelf_mysql_network-R4 `
    backup_mysql_network-R94 backup_mysql_network-R75 `
    backup_mysql_network-R74 micro_auth_network_R1001 `
    api_gateway_apache_network-R1015 micro_auth_mysql_network-R10014 `
    micro_list_reg_books_network_R1002 micro_list_reg_books_mysql_network-R10024 *> $null
  docker volume rm mysql-data audit_logs -f *> $null

  Write-Host "INFO" -ForegroundColor Blue -NoNewline
  Write-Host ": enviroment cleaning finished!"
}


# -----------------------------
# 4. Check port availability
# -----------------------------
$porta3306 = Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue
if ($porta3306) {
    Write-Host "`nERROR" -ForegroundColor Red -NoNewline
    Write-Host ": the port 3306 is already in using by another application. Please, verify if MySQL or another service is running in 3306 port. Run for troubleshoot:"
    Write-Host "Get-NetTCPConnection -LocalPort 3306 | Format-Table"
    Write-Host "See also if another Docker container is using the port 3306:"
    Write-Host "docker ps"
    exit 1
}

$porta80 = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
if ($porta80) {
    Write-Host "`nERROR: the port 80 is already in using by another application. Please, verify if Apache or another service is running in 3306 port. Run for troubleshoot:"
    Write-Host "Get-NetTCPConnection -LocalPort 80 | Format-Table"
    Write-Host "See also if another Docker container is using the port 80:"
    Write-Host "docker ps"
    exit 1
}


# -----------------------------
# 5. Create Docker networks
# -----------------------------
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker networks"

Write-Host "Network 'apache_network-R5' (ip-range: 10.0.5.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5 

Write-Host "`nNetwork 'mysql_network-R4' (ip-range: 10.0.4.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4

Write-Host "`nNetwork 'apache_mysql_network-R4-5' (ip-range: 10.0.45.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

# backup
Write-Host "`nNetwork 'backup_mysql_network-R94' (ip-range: 10.0.94.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.94.0/24 --ip-range=10.0.94.0/24 --gateway=10.0.94.254 backup_mysql_network-R94

# REST API
## API_GATEWAY <> Apache
Write-Host "`nNetwork 'api_gateway_apache_network-R1015' (10.101.0.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.101.0.0/24 --ip-range=10.101.0.0/24 --gateway=10.101.0.254 api_gateway_apache_network-R1015

### [Micro-Auth]
## API_GATEWAY <> Micro-Auth
Write-Host "`nNetwork 'micro_auth_network_R1001' (10.100.1.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.100.1.0/24 --ip-range=10.100.1.0/24 --gateway=10.100.1.254 micro_auth_network_R1001

## Micro-Auth <> MySQL
Write-Host "`nNetwork 'micro_auth_mysql_network-R10014' (10.100.14.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.100.14.0/24 --ip-range=10.100.14.0/24 --gateway=10.100.14.254 micro_auth_mysql_network-R10014

### [Micro-List-Reg-Books]
## API_GATEWAY <> Micro-List-Reg-Books
Write-Host "`nNetwork 'micro_list_reg_books_network_R1002' (10.100.2.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.100.2.0/24 --ip-range=10.100.2.0/24 --gateway=10.100.2.254 micro_list_reg_books_network_R1002

## Micro-List-Reg-Books <> MySQL
Write-Host "`nNetwork 'micro_list_reg_books_mysql_network-R10024' (10.100.24.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.100.24.0/24 --ip-range=10.100.24.0/24 --gateway=10.100.24.254 micro_list_reg_books_mysql_network-R10024


# -----------------------------
# 6. Apache/PHP container setup
# -----------------------------
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting the creation of Apache 8.2 'ubuntu_apache' container..."

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": deploying Apache/PHP container..."

$file_path=(Get-Location).Path -replace '\\', '/'

docker build -t apache_openshelf_image -f ../docker/apache/apache.dockerfile ../../..
docker create --name ubuntu_apache -p 80:80 apache_openshelf_image

docker network connect --ip 10.0.5.10 apache_network-R5 ubuntu_apache
docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache
docker network connect --ip 10.101.0.11 api_gateway_apache_network-R1015 ubuntu_apache

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting 'ubuntu_apache' container and Apache2 service"
docker start ubuntu_apache


# -----------------------------
# 7. MySQL container setup
# -----------------------------

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting the creation of MySQL 8.0 'mysql_stable' container..."

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker volume 'mysql-data'..."
docker volume create mysql-data | out-null

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": preparing enviroment and installing dependencies"
docker build -t mysql_openshelf_image -f ../docker/sql/mysql.dockerfile ../docker/sql/
docker create --name mysql_stable -p 3306:3306 -e MYSQL_ROOT_PASSWORD=passwd -v mysql-data:/var/lib/mysql mysql_openshelf_image

docker network connect --ip 10.0.4.10 mysql_network-R4 mysql_stable
docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable
docker network connect --ip 10.0.94.11 backup_mysql_network-R94 mysql_stable
docker network connect --ip 10.100.14.10 micro_auth_mysql_network-R10014 mysql_stable
docker network connect --ip 10.100.24.10 micro_list_reg_books_mysql_network-R10024 mysql_stable

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting 'mysql_stable' container and MySQL service"
docker start mysql_stable


# -----------------------------
# 8. API Gateway container setup
# -----------------------------

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting the creation of Debian 12 'debian_api_gateway' container..."

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker volume 'audit_logs'..."
docker volume create audit_logs | out-null

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": preparing enviroment and installing dependencies"
docker build --platform=linux/amd64 -t debian_api_gateway_openshelf_image -f ../docker/api_gateway/api_gateway.dockerfile ../docker/api_gateway
docker create --name debian_api_gateway -p 5000:5000 -v audit_logs:/var/log/audit_log debian_api_gateway_openshelf_image

docker network connect --ip 10.101.0.10 api_gateway_apache_network-R1015 debian_api_gateway
docker network connect --ip 10.100.1.11 micro_auth_network_R1001 debian_api_gateway
docker network connect --ip 10.100.2.11 micro_list_reg_books_network_R1002 debian_api_gateway

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting 'debian_api_gateway' container and API Gateway service"
docker start debian_api_gateway

docker exec -i debian_api_gateway bash -c "touch /var/log/audit_log/openshelf_audit.log && chmod go-rwx /var/log/audit_log/openshelf_audit.log"


# -----------------------------
# 9. Micro Auth
# -----------------------------

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting the creation of Debian 12 'micro_auth_api' container..."

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": preparing enviroment and installing dependencies"
docker build --platform=linux/amd64 -t micro-auth_openshelf_image -f ../docker/micro-auth/auth.dockerfile ../docker/micro-auth
docker create --name micro_auth_api -p 5001:5001 micro-auth_openshelf_image

docker network connect --ip 10.100.14.11 micro_auth_mysql_network-R10014 micro_auth_api
docker network connect --ip 10.100.1.10 micro_auth_network_R1001 micro_auth_api

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting 'micro_auth_api' container and API Gateway service"
docker start micro_auth_api


# -----------------------------
# 10. Micro List Reg Books
# -----------------------------

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting the creation of Debian 12 'micro_list_reg_books_api' container..."

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": preparing enviroment and installing dependencies"
docker build --platform=linux/amd64 -t micro-list_reg_books_openshelf_image -f ../docker/micro-list-reg-books/list_reg.dockerfile ../docker/micro-list-reg-books
docker create --name micro_list_reg_books_api -p 5002:5002 micro-list_reg_books_openshelf_image

docker network connect --ip 10.100.24.11 micro_list_reg_books_mysql_network-R10024 micro_list_reg_books_api
docker network connect --ip 10.100.2.10 micro_list_reg_books_network_R1002 micro_list_reg_books_api

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": starting 'micro_list_reg_books_api' container and API Gateway service"
docker start micro_list_reg_books_api


Write-Host "`n`n`n==============[APACHE]=============="
Write-Host "`n`nCONTAINER INFORMATION:"
Write-Host "Apache server with PHP 8.2 installed"
Write-Host "Included extension: pdo_mysql"
Write-Host "Enabled Apache module: rewrite"
Write-Host "`n`nTo access the container:"
Write-Host "docker exec -it ubuntu_apache bash"
Write-Host "`n`nTo check Apache Error Logs:"
Write-Host "docker exec -it ubuntu_apache bash -c 'tail -f /var/log/apache2/error.log'"
Write-Host "`n`nTo test PHP:"
Write-Host "Open in your browser: http://localhost/library"

Write-Host "`n`n`n===============[MySQL]==============="
Write-Host "`n`nCREDENCIAIS DO DOCKER:`nuser: root`nPassword: passwd"
Write-Host "`n`nPara acessar o docker:`ndocker start mysql_stable`ndocker exec -it mysql_stable mysql -u root -p"
Write-Host "`n`nDetalhes de rede:`nNome: mysql_network-R4`nGateway:10.0.4.254`nip-range: 10.0.4.0/24`nContainer IP: 10.0.4.11`n`n"
