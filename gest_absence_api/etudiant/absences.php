<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include("../config/db_connect.php");

$response = array();

if (isset($_GET["id"])) {
    $id = $_GET["id"];
    
    $sql = "SELECT a.statut, s.date_seance, s.heure_debut, m.nom as matiere 
            FROM absences a 
            JOIN seances s ON a.seance_id = s.id 
            JOIN matieres m ON s.matiere_id = m.id 
            WHERE a.etudiant_id = ? 
            ORDER BY s.date_seance DESC";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$id]);
    $absences = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $absences;
} else {
    $response["success"] = 0;
    $response["message"] = "Student id required";
}

echo json_encode($response);
?>