<?php
include("../config/database.php");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // 1. Get raw input
    $json = file_get_contents("php://input");
    $data = json_decode($json, true);

    // 2. Check if JSON was valid and has data
    if (!$data || !isset($data['seance_id']) || !isset($data['appel'])) {
        echo json_encode([
            "status" => "Error", 
            "message" => "Invalid JSON or missing fields (seance_id/appel)"
        ]);
        exit;
    }

    $seance_id = $data['seance_id'];
    $appel = $data['appel']; 

    try {
        $sql = "INSERT INTO absences (seance_id, etudiant_id, statut) VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE statut = VALUES(statut)";
        $stmt = $pdo->prepare($sql);

        foreach ($appel as $row) {
            $stmt->execute([$seance_id, $row['etudiant_id'], $row['statut']]);
        }
        echo json_encode(["status" => "Success", "message" => "Attendance updated"]);
    } catch (Exception $e) {
        echo json_encode(["status" => "Error", "message" => $e->getMessage()]);
    }
}