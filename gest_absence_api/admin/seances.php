<?php
include("../config/database.php");

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true) ?: $_POST;
    
    $sql = "INSERT INTO seances (enseignant_id, classe_id, matiere_id, date_seance, heure_debut, heure_fin) 
            VALUES (?, ?, ?, ?, ?, ?)";
    $stmt = $pdo->prepare($sql);
    
    if($stmt->execute([$data['enseignant_id'], $data['classe_id'], $data['matiere_id'], $data['date_seance'], $data['heure_debut'], $data['heure_fin']])) {
        echo json_encode(["status" => "Success"]);
    } else {
        echo json_encode(["status" => "Error"]);
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $stmt = $pdo->query("SELECT s.*, u.nom as prof_nom, c.nom as classe_nom, m.nom as matiere_nom 
                         FROM seances s
                         JOIN enseignants e ON s.enseignant_id = e.id
                         JOIN utilisateurs u ON e.utilisateur_id = u.id
                         JOIN classes c ON s.classe_id = c.id
                         JOIN matieres m ON s.matiere_id = m.id");
    echo json_encode($stmt->fetchAll());
}