#!/usr/bin/env pwsh

# Data atual no formato YYYY-MM-DD
$date = (Get-Date).ToString('yyyy-MM-dd')

# Códigos de cor ANSI (funciona se o terminal estiver em modo Virtual Terminal)
$RED    = "`e[31m"
$BLUE   = "`e[34m"
$YELLOW = "`e[33m"
$NC     = "`e[0m"

# -----------------------------
# 1. Verificar se o Docker está instalado
# -----------------------------
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "${RED}ERROR${NC}: Docker não está instalado."
    exit 1
}

# -----------------------------
# 2. Verificar se o Docker está em execução
# -----------------------------
try {
    docker info | Out-Null
} catch {
    Write-Host "${RED}ERROR${NC}: Docker não está em execução."
    exit 1
}

Write-Host ""
Write-Host "-----------------------------"
Write-Host "Welcome to Openshelf Backup Center!"
Write-Host "-----------------------------"
Write-Host ""
Write-Host " (1) Make Backup"
Write-Host " (2) Put Backup on prod"
Write-Host ""
$escolha = Read-Host "="


# -----------------------------
# 1. Make Backup
# -----------------------------
if ($escolha -eq '1') {
    Write-Host ""
    Write-Host "`nWARN" -ForegroundColor Yellow -NoNewline
    Write-Host ": 'Make Backup' option selected"

    # Definir e sanitizar nome do volume
    $backupVolume = ("backup-mysql-data-$date").Trim()

    # Criar volume de backup
    docker volume create $backupVolume | Out-Null

    docker run -d `
        --name backup_mysql `
        -v mysql-data:/mnt/mysql `
        -v ${backupVolume}:/mnt/backup `
        --network backup_mysql_network-R94 `
        --ip 10.0.94.10 `
        mysql:latest `
        bash -c "mysqldump -h 10.0.94.11 -u root -ppasswd --databases openshelf > /mnt/backup/mysql-backup.sql"

    docker stop backup_mysql
    docker rm backup_mysql

    Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
    Write-Host " : backup volume '$backupVolume' criado"

}
# -----------------------------
# 2. Put Backup on prod
# -----------------------------
elseif ($escolha -eq '2') {
    Write-Host "`nWARN" -ForegroundColor Yellow -NoNewline
    Write-Host " : 'Put Backup on prod' option selected"

    # Listar volumes de backup existentes
    $volumes = docker volume ls -q | Where-Object { $_ -like 'backup-mysql-data*' }

    if ($volumes.Count -eq 0) {
        Write-Host "`nERROR" -ForegroundColor Red -NoNewline
        Write-Host " : Nenhum volume de backup encontrado."
        exit 1
    }

    Write-Host ""
    Write-Host "Selecione algum backup de volume para restaurar em produção:"
    # Executa o docker e força o resultado a ser um array
    $volumeNames = @(docker volume ls -q)

    # Teste: mostre o conteúdo e confirme que é um array
    Write-Host "Volumes encontrados:"
    for ($i=0; $i -le $volumeNames.Length - 1; $i=$i+1 ) {
        Write-Host "($i) - " ${volumeNames}[$i];
    }

    $backup_chosed = Read-Host "Qual backup deseja escolher?`n="
    $backup_chosed = ${volumeNames}[$backup_chosed]

    Write-Host "`nWARN" -ForegroundColor Yellow -NoNewline
    Write-Host " : Replacing actual MySQL data with '$backup_chosed'"

    # Resetar banco openshelf no container de produção
    docker exec -i mysql_stable mysql -u root -ppasswd `
        -e "DROP DATABASE IF EXISTS openshelf; CREATE DATABASE openshelf;"

    # Restaurar dump
    docker run -d `
        --name backup_mysql `
        -v mysql-data:/mnt/mysql `
        -v ${backup_chosed}:/mnt/backup `
        --network backup_mysql_network-R94 `
        --ip 10.0.94.10 `
        mysql:latest `
        bash -c "mysql -h 10.0.94.11 -u root -ppasswd openshelf < /mnt/backup/mysql-backup.sql" | Out-Null

    docker stop backup_mysql | Out-Null
    docker rm backup_mysql   | Out-Null

    Write-Host "`nINFO" -ForegroundColor Blue -NoNewline
    Write-Host " : volume substitution concluded!"
}
else {
    Write-Host "`nERROR" -ForegroundColor Red -NoNewline
    Write-Host " : Opção inválida."
    exit 1
}
