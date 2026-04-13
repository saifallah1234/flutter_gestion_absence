<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST");

include("../config/db_connect.php");

$method = $_SERVER["REQUEST_METHOD"];
$response = array();

// GET 
if ($method == "GET") {
    $result = $pdo->query("SELECT id, nom, niveau FROM classes ORDER BY nom");
    $classes = $result->fetchAll(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $classes;
    echo json_encode($response);
}

// POST 
elseif ($method == "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (isset($data["nom"])) {
        $sql = "INSERT INTO classes (nom, niveau) VALUES (?, ?)";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$data["nom"], $data["niveau"] ?? null]);
        
        $response["success"] = 1;
        $response["message"] = "Class added successfully";
    } else {
        $response["success"] = 0;
        $response["message"] = "Class name required";
    }
    echo json_encode($response);
}
?>