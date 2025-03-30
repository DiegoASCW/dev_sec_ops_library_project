<?php 
// DB credentials.
define('DB_USER','library');
define('DB_PASS','passwd');
define('DB_NAME','library');

// Establish database connection.
try {
    $dbh = new PDO("mysql:host=127.0.0.1;dbname=".DB_NAME,DB_USER, DB_PASS,array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8'"));
}
catch (PDOException $e) {
    exit("Error: " . $e->getMessage());
}
?>