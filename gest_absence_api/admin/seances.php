<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../config/db_connect.php");

$method = $_SERVER["REQUEST_METHOD"];
$response = array();

if (!isset($pdo)) {
    echo json_encode(["success" => 0, "message" => "Database connection failed"]);
    exit;
}

// GET - List all seances OR dropdown lists
if ($method == "GET") {
    // Check if we need dropdown lists for forms
    if (isset($_GET['lists']) && $_GET['lists'] == 'true') {
        // Get all teachers
        $teachers = $pdo->query("SELECT e.id, CONCAT(u.prenom, ' ', u.nom) as nom FROM enseignants e JOIN utilisateurs u ON e.utilisateur_id = u.id ORDER BY u.nom")->fetchAll(PDO::FETCH_ASSOC);
        
        // Get all classes
        $classes = $pdo->query("SELECT id, nom FROM classes ORDER BY nom")->fetchAll(PDO::FETCH_ASSOC);
        
        // Get all matieres
        $matieres = $pdo->query("SELECT id, nom FROM matieres ORDER BY nom")->fetchAll(PDO::FETCH_ASSOC);
        
        $response["success"] = 1;
        $response["data"] = [
            "enseignants" => $teachers,
            "classes" => $classes,
            "matieres" => $matieres
        ];
        echo json_encode($response);
        exit;
    }
    
    // Regular GET - List all seances
    $sql = "SELECT s.id, s.date_seance, s.heure_debut, s.heure_fin,
                   m.nom as matiere, 
                   c.nom as classe, 
                   CONCAT(u.prenom, ' ', u.nom) as enseignant
            FROM seances s
            JOIN matieres m ON s.matiere_id = m.id
            JOIN classes c ON s.classe_id = c.id
            JOIN enseignants e ON s.enseignant_id = e.id
            JOIN utilisateurs u ON e.utilisateur_id = u.id
            ORDER BY s.date_seance DESC, s.heure_debut";
    
    $result = $pdo->query($sql);
    $seances = $result->fetchAll(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $seances;
    echo json_encode($response);
}

// POST - Add new seance
elseif ($method == "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (isset($data["enseignant_id"]) && isset($data["classe_id"]) && 
        isset($data["matiere_id"]) && isset($data["date_seance"]) && 
        isset($data["heure_debut"]) && isset($data["heure_fin"])) {
        
        // Check if enseignant exists
        $stmt = $pdo->prepare("SELECT id FROM enseignants WHERE id = ?");
        $stmt->execute([$data["enseignant_id"]]);
        if (!$stmt->fetch()) {
            $response["success"] = 0;
            $response["message"] = "Teacher not found";
            echo json_encode($response);
            exit;
        }
        
        // Check if classe exists
        $stmt = $pdo->prepare("SELECT id FROM classes WHERE id = ?");
        $stmt->execute([$data["classe_id"]]);
        if (!$stmt->fetch()) {
            $response["success"] = 0;
            $response["message"] = "Class not found";
            echo json_encode($response);
            exit;
        }
        
        // Check if matiere exists
        $stmt = $pdo->prepare("SELECT id FROM matieres WHERE id = ?");
        $stmt->execute([$data["matiere_id"]]);
        if (!$stmt->fetch()) {
            $response["success"] = 0;
            $response["message"] = "Subject not found";
            echo json_encode($response);
            exit;
        }
        
        $sql = "INSERT INTO seances (enseignant_id, classe_id, matiere_id, date_seance, heure_debut, heure_fin) 
                VALUES (?, ?, ?, ?, ?, ?)";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $data["enseignant_id"],
            $data["classe_id"],
            $data["matiere_id"],
            $data["date_seance"],
            $data["heure_debut"],
            $data["heure_fin"]
        ]);
        
        $response["success"] = 1;
        $response["message"] = "Seance added successfully";
        $response["data"] = ["id" => $pdo->lastInsertId()];
    } else {
        $response["success"] = 0;
        $response["message"] = "Missing fields: enseignant_id, classe_id, matiere_id, date_seance, heure_debut, heure_fin";
    }
    echo json_encode($response);
}

else {
    $response["success"] = 0;
    $response["message"] = "Method not allowed";
    echo json_encode($response);
}
?>