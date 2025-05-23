# Check if 'Docker' in installed
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host ": Docker is not installed." 
    exit 1
}

# Check if 'Docker' is running
docker info > $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR" -ForegroundColor Red -NoNewline
    Write-Host ": Docker is not running."
    exit 1
}

# Enviroment cleaning
$escolha = Read-Host "`nDo you want to clean the enviroment (recomended in case of redeploy the infraestructure)?  [y/N] "

if ($escolha -eq "y") {
  Write-Host "INFO" -ForegroundColor Blue -NoNewline
  Write-Host ": removing containers, networks, volumes, and images, about 'Openshelf' project"

  docker stop ubuntu_apache mysql_stable -t 0 *> $null
  docker rm ubuntu_apache mysql_stable mysql-stable *> $null
  #docker rmi diegolautenscs/personal_stables:mysql-openshelf-v3 diegolautenscs/web_sec_stables:mysql-openshelf-v12 mysql-openshelf-v12 mysql php:8.2-apache -f *> $null
  docker network rm apache_network-R5 mysql_network-R4 apache_mysql_network-R4-5 openshelf_mysql_network-R4 backup_mysql_network-R94 *> $null
  docker volume rm mysql-data -f *> $null

  Write-Host "INFO" -ForegroundColor Blue -NoNewline
  Write-Host ": enviroment cleaning finished!"
}

# Check the availability for port 3306
$porta3306 = Get-NetTCPConnection -LocalPort 3306 -State Listen -ErrorAction SilentlyContinue
if ($porta3306) {
    Write-Host "`nERROR" -ForegroundColor Red -NoNewline
    Write-Host ": the port 3306 is already in using by another application. Please, verify if MySQL or another service is running in 3306 port. Run for troubleshoot:"
    Write-Host "Get-NetTCPConnection -LocalPort 3306 | Format-Table"
    Write-Host "See also if another Docker container is using the port 3306:"
    Write-Host "docker ps"
    exit 1
}

# Check the availability for port 80
$porta80 = Get-NetTCPConnection -LocalPort 80 -State Listen -ErrorAction SilentlyContinue
if ($porta80) {
    Write-Host "`nERROR: the port 80 is already in using by another application. Please, verify if Apache or another service is running in 3306 port. Run for troubleshoot:"
    Write-Host "Get-NetTCPConnection -LocalPort 80 | Format-Table"
    Write-Host "See also if another Docker container is using the port 80:"
    Write-Host "docker ps"
    exit 1
}

# Step 1: Create Docker networks
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker networks"

Write-Host "Network 'apache_network-R5' (ip-range: 10.0.5.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.5.0/24 --ip-range=10.0.5.0/24 --gateway=10.0.5.254 apache_network-R5 

Write-Host "`nNetwork 'mysql_network-R4' (ip-range: 10.0.4.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.4.0/24 --ip-range=10.0.4.0/24 --gateway=10.0.4.254 mysql_network-R4

Write-Host "`nNetwork 'apache_mysql_network-R4-5' (ip-range: 10.0.45.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.45.0/24 --ip-range=10.0.45.0/24 --gateway=10.0.45.254 apache_mysql_network-R4-5

Write-Host "`nNetwork 'backup_mysql_network-R94' (ip-range: 10.0.94.0/24): " -ForegroundColor Blue -NoNewline
docker network create --driver bridge --subnet=10.0.94.0/24 --ip-range=10.0.94.0/24 --gateway=10.0.94.254 backup_mysql_network-R94


# ===============[APACHE]===============
# Step 2: Run the Apache/PHP container
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Apache/PHP container..."

# Convert the current working directory to a Unix-friendly path (replace backslashes with forward slashes)
$pwdUnix = ($PWD.Path -replace "\\", "/")

docker run -d `
  --name ubuntu_apache `
  -p 80:80 `
  --network apache_network-R5 `
  --ip 10.0.5.10 `
  -v "$pwdUnix/../../Projeto_Web/site:/var/www/html" `
  php:8.2-apache `
  bash -c 'docker-php-ext-install pdo_mysql && a2enmod rewrite && apache2-foreground'

docker cp ./captcha_dependencies.sh ubuntu_apache:/tmp

Start-Sleep -Seconds 10

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": installing dependencies for Apache2 'GD' into 'ubuntu_apache' container..."
docker exec -i ubuntu_apache bash "/tmp/captcha_dependencies.sh" | out-null

docker restart ubuntu_apache

docker network connect --ip 10.0.45.20 apache_mysql_network-R4-5 ubuntu_apache

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": docker Apache/PHP environment created successfully!"

# ===============[MYSQL]===============
# Step 2: Create the Docker volume for MySQL data persistence
Write-Host "`n`n`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating Docker volume 'mysql-data'"
docker volume create mysql-data | Out-Null

# Step 3: Run the MySQL container
Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": creating MySQL container"
docker pull mysql

docker run -d `
  --name mysql_stable `
  -v mysql-data:/var/lib/mysql `
  -p 3306:3306 `
  -e MYSQL_ROOT_PASSWORD=passwd `
  mysql

docker network connect --ip 10.0.4.10 mysql_network-R4 mysql_stable
docker network connect --ip 10.0.45.10 apache_mysql_network-R4-5 mysql_stable
docker network connect --ip 10.0.94.11 backup_mysql_network-R94 mysql_stable

Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
Write-Host ": waiting for 'mysqld' service start..."

$teste = $true

while ($teste) {
    try {
        docker exec mysql_stable mysql -u root -ppasswd -e "SHOW SCHEMAS;" > $null 2>&1
        if ($LASTEXITCODE -eq 0) {
            Start-Sleep -Seconds 5
            $teste = $false
        } else {
            Start-Sleep -Seconds 1
        }
    } catch {
        Start-Sleep -Seconds 1
    }
}


docker cp ./openshelf-setup.sql mysql_stable:/tmp

docker exec -i mysql_stable mysql -u root -ppasswd -e "source /tmp/openshelf-setup.sql"

Write-Host "`nWARN" -ForegroundColor Yellow -NoNewline
Write-Host ": check if the database 'openshelf' is underneath:"
docker exec -i mysql_stable mysql -u root -ppasswd -e "SHOW DATABASES;"
Write-Host "`n"



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
