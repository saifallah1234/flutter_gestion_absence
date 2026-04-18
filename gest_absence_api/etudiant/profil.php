<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include("../config/db_connect.php");

$response = array();

if (isset($_GET["id"])) {
    $id = $_GET["id"];
    
    $sql = "SELECT u.id, u.nom, u.prenom, u.email, c.nom as classe 
            FROM utilisateurs u 
            JOIN etudiants e ON u.id = e.utilisateur_id 
            JOIN classes c ON e.classe_id = c.id 
            WHERE e.id = ?";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$id]);
    $profile = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($profile) {
    $profile['id'] = (int) $profile['id'];

    $response["success"] = 1;
    $response["data"] = $profile;
}
    
    if ($profile) {
        $response["success"] = 1;
        $response["data"] = $profile;
    } else {
        $response["success"] = 0;
        $response["message"] = "Student not found";
    }
} else {
    $response["success"] = 0;
    $response["message"] = "Student id required";
}

echo json_encode($response);
?>