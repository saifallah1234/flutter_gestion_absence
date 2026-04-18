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

// Fonction pour ajouter une notification
function addNotification($pdo, $user_id, $user_type, $title, $message, $type = 'absence') {
    $sql = "INSERT INTO notifications (user_id, user_type, title, message, type, is_read, created_at) 
            VALUES (?, ?, ?, ?, ?, 0, NOW())";
    $stmt = $pdo->prepare($sql);
    return $stmt->execute([$user_id, $user_type, $title, $message, $type]);
}

// Fonction pour récupérer l'utilisateur_id d'un étudiant
function getEtudiantUserId($pdo, $etudiant_id) {
    $sql = "SELECT u.id, u.nom, u.prenom 
            FROM utilisateurs u 
            JOIN etudiants e ON u.id = e.utilisateur_id 
            WHERE e.id = ?";
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$etudiant_id]);
    return $stmt->fetch(PDO::FETCH_ASSOC);
}

// ==========================================
// ACTION 1 : RÉCUPÉRER LES ÉTUDIANTS (GET)
// ==========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['classe_id'])) {
    $classe_id = $_GET['classe_id'];

    try {
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
    exit;
}

// ==========================================
// ACTION 2 : RÉCUPÉRER L'APPEL EXISTANT
// ==========================================
if ($_SERVER['REQUEST_METHOD'] === 'GET' && isset($_GET['seance_id'])) {
    $seance_id = $_GET['seance_id'];
    
    try {
        $sql = "SELECT etudiant_id, statut FROM absences WHERE seance_id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$seance_id]);
        $absences = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        echo json_encode(["status" => "Success", "data" => $absences]);
    } catch (Exception $e) {
        echo json_encode(["status" => "Error", "message" => $e->getMessage()]);
    }
    exit;
}

// ==========================================
// ACTION 3 : SOUMETTRE L'APPEL (POST) - AVEC NOTIFICATIONS
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
        $pdo->beginTransaction();
        
        // Récupérer les informations de la séance
        $sqlSeance = "SELECT s.date_seance, s.heure_debut, s.heure_fin, 
                             m.nom as matiere, c.nom as classe, c.id as classe_id,
                             CONCAT(u.nom, ' ', u.prenom) as enseignant
                      FROM seances s
                      JOIN matieres m ON s.matiere_id = m.id
                      JOIN classes c ON s.classe_id = c.id
                      JOIN enseignants e ON s.enseignant_id = e.id
                      JOIN utilisateurs u ON e.utilisateur_id = u.id
                      WHERE s.id = ?";
        $stmtSeance = $pdo->prepare($sqlSeance);
        $stmtSeance->execute([$seance_id]);
        $seanceInfo = $stmtSeance->fetch(PDO::FETCH_ASSOC);
        
        // Récupérer les absences existantes
        $sqlOld = "SELECT etudiant_id, statut FROM absences WHERE seance_id = ?";
        $stmtOld = $pdo->prepare($sqlOld);
        $stmtOld->execute([$seance_id]);
        $oldAbsences = [];
        while ($row = $stmtOld->fetch(PDO::FETCH_ASSOC)) {
            $oldAbsences[$row['etudiant_id']] = $row['statut'];
        }
        
        // Insérer ou mettre à jour les absences
        $sql = "INSERT INTO absences (seance_id, etudiant_id, statut) VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE statut = VALUES(statut)";
        $stmt = $pdo->prepare($sql);
        
        $notificationsSent = 0;

        foreach ($appel as $row) {
            $etudiant_id = $row['etudiant_id'];
            $statut = strtolower($row['statut']);
            if (!in_array($statut, ['present', 'absent', 'justifie'])) {
                $statut = 'present';
            }
            $stmt->execute([$seance_id, $etudiant_id, $statut]);
            
            $oldStatut = isset($oldAbsences[$etudiant_id]) ? $oldAbsences[$etudiant_id] : null;
            
            // Récupérer l'étudiant
            $etudiant = getEtudiantUserId($pdo, $etudiant_id);
            
            if ($etudiant) {
                $dateFormatted = date('d/m/Y', strtotime($seanceInfo['date_seance']));
                
                // Cas 1 : Nouvelle absence
                if ($statut == 'absent' && $oldStatut != 'absent') {
                    addNotification(
                        $pdo,
                        $etudiant['id'],
                        'etudiant',
                        '📚 Nouvelle absence',
                        "Absence en {$seanceInfo['matiere']} ({$seanceInfo['classe']}) le {$dateFormatted}",
                        'absence'
                    );
                    $notificationsSent++;
                }
                
                // Cas 2 : Absence justifiée (si vous avez ce statut)
                if ($statut == 'justifie' && $oldStatut == 'absent') {
                    addNotification(
                        $pdo,
                        $etudiant['id'],
                        'etudiant',
                        '✅ Absence justifiée',
                        "Votre absence en {$seanceInfo['matiere']} du {$dateFormatted} a été justifiée",
                        'info'
                    );
                    $notificationsSent++;
                }
            }
        }
        
        $pdo->commit();
        
        echo json_encode([
            "status" => "Success", 
            "message" => "Appel enregistré avec succès",
            "notifications_sent" => $notificationsSent
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        echo json_encode([
            "status" => "Error", 
            "message" => $e->getMessage()
        ]);
    }
}
?>