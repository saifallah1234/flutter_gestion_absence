<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
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

// GET - List all matieres
if ($method == "GET") {
    $sql = "SELECT id, nom FROM matieres ORDER BY nom";
    $result = $pdo->query($sql);
    $matieres = $result->fetchAll(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $matieres;
    echo json_encode($response);
}

// POST - Add new matiere
elseif ($method == "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (isset($data["nom"]) && !empty(trim($data["nom"]))) {
        $nom = trim($data["nom"]);
        
        // Check if matiere already exists
        $stmt = $pdo->prepare("SELECT id FROM matieres WHERE LOWER(nom) = LOWER(?)");
        $stmt->execute([$nom]);
        
        if ($stmt->fetch()) {
            $response["success"] = 0;
            $response["message"] = "Cette matière existe déjà";
        } else {
            $sql = "INSERT INTO matieres (nom) VALUES (?)";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$nom]);
            
            $response["success"] = 1;
            $response["message"] = "Matière ajoutée avec succès";
            $response["data"] = [
                "id" => $pdo->lastInsertId(),
                "nom" => $nom
            ];
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "Le nom de la matière est requis";
    }
    echo json_encode($response);
}

// PUT - Update matiere
elseif ($method == "PUT") {
    $data = json_decode(file_get_contents("php://input"), true);
    $id = isset($_GET['id']) ? intval($_GET['id']) : (isset($data['id']) ? intval($data['id']) : null);
    
    if ($id && isset($data["nom"]) && !empty(trim($data["nom"]))) {
        $nom = trim($data["nom"]);
        
        $sql = "UPDATE matieres SET nom = ? WHERE id = ?";
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$nom, $id]);
        
        $response["success"] = 1;
        $response["message"] = "Matière modifiée avec succès";
    } else {
        $response["success"] = 0;
        $response["message"] = "ID et nom de la matière requis";
    }
    echo json_encode($response);
}

// DELETE - Remove matiere
elseif ($method == "DELETE") {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    
    if ($id) {
        // Check if matiere is used in seances
        $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM seances WHERE matiere_id = ?");
        $stmt->execute([$id]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result['count'] > 0) {
            $response["success"] = 0;
            $response["message"] = "Impossible de supprimer : cette matière est utilisée dans des séances";
        } else {
            $sql = "DELETE FROM matieres WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$id]);
            
            $response["success"] = 1;
            $response["message"] = "Matière supprimée avec succès";
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "ID matière requis";
    }
    echo json_encode($response);
}
?>