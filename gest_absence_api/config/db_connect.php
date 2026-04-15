<?php
// --- CORS Configuration ---
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request from Flutter Web
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
// --------------------------

$host = 'gateway01.eu-central-1.prod.aws.tidbcloud.com';
$port = '4000';
$db   = 'gest_absence';
$user = 'dMdAF7Rr2CkTmaZ.root';
$pass = 'w5Q6r46FgMHp1meL';

try {
    $dsn = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";
    
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        // CRITICAL FIX: Explicitly signal SSL usage
        PDO::MYSQL_ATTR_SSL_CA => true, 
        PDO::MYSQL_ATTR_SSL_VERIFY_SERVER_CERT => false,
    ];

    $pdo = new PDO($dsn, $user, $pass, $options);
    
} catch (PDOException $e) {
    // If it still fails, let's output the full error to see if it's SSL or IP Whitelist
    echo json_encode([
        "status" => "error", 
        "message" => $e->getMessage(),
        "hint" => "Check if your IP is whitelisted in TiDB Cloud Console"
    ]);
    exit;
}
?>