<?php 
// DB credentials.
define('DB_HOST','10.0.45.10');
define('DB_USER','root');
define('DB_PASS','passwd');
define('DB_NAME','openshelf');
// Establish database connection.
try
{
$dbh = new PDO("mysql:host=".DB_HOST.";dbname=".DB_NAME,DB_USER, DB_PASS,array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES 'utf8'"));
}
catch (PDOException $e)
{
exit("Error: " . $e->getMessage());
}
?>