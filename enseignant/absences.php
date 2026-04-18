<?php
// En-têtes CORS obligatoires pour Flutter Web
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../config/db_connect.php");

// ==========================================
// ACTION 1 : RÉCUPÉRER LES ÉTUDIANTS (GET)
// ==========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['classe_id'])) {
    $classe_id = $_GET['classe_id'];

    try {
        // Jointure entre 'utilisateurs' et 'etudiants'
        $sql = "SELECT e.id, e.utilisateur_id, u.nom, u.prenom, e.classe_id 
                FROM utilisateurs u 
                JOIN etudiants e ON u.id = e.utilisateur_id 
                WHERE e.classe_id = ?";
                
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$classe_id]);
        
        $etudiants = $stmt->fetchAll(PDO::FETCH_ASSOC);
        echo json_encode($etudiants);
    } catch (Exception $e) {
        echo json_encode(["status" => "Error", "message" => $e->getMessage()]);
    }
    exit; // On arrête l'exécution ici pour le GET
}

// ==========================================
// ACTION 2 : SOUMETTRE L'APPEL (POST) - Votre code intact
// ==========================================
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $json = file_get_contents("php://input");
    $data = json_decode($json, true);

    if (!$data || !isset($data['seance_id']) || !isset($data['appel'])) {
        echo json_encode([
            "status" => "Error", 
            "message" => "Invalid JSON or missing fields"
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
            $statut = strtolower($row['statut']);
            if (!in_array($statut, ['present', 'absent'])) {
                $statut = 'present';
            }
            $stmt->execute([$seance_id, $row['etudiant_id'], $statut]);
        }
        
        echo json_encode(["status" => "Success", "message" => "Attendance updated"]);
    } catch (Exception $e) {
        echo json_encode(["status" => "Error", "message" => $e->getMessage()]);
    }
}
?>