<?php
// DB credentials.
define('DB_HOST','10.0.45.10'); 
define('DB_PORT','3306');
define('DB_USER','admin');
define('DB_PASS','passwd');
define('DB_NAME','openshelf');

try {
    $dsn = sprintf(
      'mysql:host=%s;port=%s;dbname=%s;charset=utf8mb4',
      DB_HOST, DB_PORT, DB_NAME
    );
    $opts = [
      PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
      PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_OBJ,
    ];
    $dbh = new PDO($dsn, DB_USER, DB_PASS, $opts);
} catch (PDOException $e) {
    exit('Erro na conexão: ' . $e->getMessage());
}
