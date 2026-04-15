<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

$host = 'gateway01.eu-central-1.prod.aws.tidbcloud.com';
$port = '4000';
$dbname = 'gest_absence';
$username = 'dMdAF7Rr2CkTmaZ.root';
$password = 'w5Q6r46FgMHp1meL';

try {
    // enable SSL pour tidb
    $pdo = new PDO(
        "mysql:host=$host;port=$port;dbname=$dbname;charset=utf8mb4",
        $username,
        $password,
        array(
            PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false,
            PDO::MYSQL_ATTR_SSL_CA => true,
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
        )
    );
    
    
} catch(PDOException $e) {
    echo json_encode(["success" => 0, "message" => "Connection failed: " . $e->getMessage()]);
}
?>