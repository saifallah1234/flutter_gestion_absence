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

// GET - List all teachers
if ($method == "GET") {
    $sql = "SELECT e.id, u.nom, u.prenom, u.email, e.specialite 
            FROM enseignants e 
            JOIN utilisateurs u ON e.utilisateur_id = u.id 
            WHERE u.role = 'enseignant'
            ORDER BY u.nom, u.prenom";
    
    $result = $pdo->query($sql);
    $teachers = $result->fetchAll(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $teachers;
    echo json_encode($response);
}

// POST - Add new teacher
elseif ($method == "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (isset($data["nom"]) && isset($data["prenom"]) && isset($data["email"]) && isset($data["password"])) {
        
        $pdo->beginTransaction();
        
        // Insert into utilisateurs
        $sql1 = "INSERT INTO utilisateurs (nom, prenom, email, password, role) VALUES (?, ?, ?, ?, 'enseignant')";
        $stmt1 = $pdo->prepare($sql1);
        $stmt1->execute([$data["nom"], $data["prenom"], $data["email"], $data["password"]]);
        $user_id = $pdo->lastInsertId();
        
        // Insert into enseignants
        $specialite = isset($data["specialite"]) ? $data["specialite"] : null;
        $sql2 = "INSERT INTO enseignants (utilisateur_id, specialite) VALUES (?, ?)";
        $stmt2 = $pdo->prepare($sql2);
        $stmt2->execute([$user_id, $specialite]);
        
        $pdo->commit();
        
        $response["success"] = 1;
        $response["message"] = "Teacher added successfully";
        $response["data"] = ["id" => $pdo->lastInsertId()];
    } else {
        $response["success"] = 0;
        $response["message"] = "Missing fields: nom, prenom, email, password";
    }
    echo json_encode($response);
}

// PUT - Update teacher
elseif ($method == "PUT") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (isset($data["id"])) {
        // Get utilisateur_id from enseignant
        $stmt = $pdo->prepare("SELECT utilisateur_id FROM enseignants WHERE id = ?");
        $stmt->execute([$data["id"]]);
        $teacher = $stmt->fetch();
        
        if ($teacher) {
            // Update utilisateurs
            $sql = "UPDATE utilisateurs SET nom = ?, prenom = ?, email = ? WHERE id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([
                $data["nom"] ?? null,
                $data["prenom"] ?? null,
                $data["email"] ?? null,
                $teacher["utilisateur_id"]
            ]);
            
            // Update specialite if provided
            if (isset($data["specialite"])) {
                $sql2 = "UPDATE enseignants SET specialite = ? WHERE id = ?";
                $stmt2 = $pdo->prepare($sql2);
                $stmt2->execute([$data["specialite"], $data["id"]]);
            }
            
            $response["success"] = 1;
            $response["message"] = "Teacher updated successfully";
        } else {
            $response["success"] = 0;
            $response["message"] = "Teacher not found";
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "Teacher id required";
    }
    echo json_encode($response);
}

// DELETE - Remove teacher
elseif ($method == "DELETE") {
    $id = isset($_GET['id']) ? intval($_GET['id']) : null;
    
    if ($id) {
        // Get utilisateur_id from enseignant
        $stmt = $pdo->prepare("SELECT utilisateur_id FROM enseignants WHERE id = ?");
        $stmt->execute([$id]);
        $teacher = $stmt->fetch();
        
        if ($teacher) {
            // Delete from enseignants first
            $stmt = $pdo->prepare("DELETE FROM enseignants WHERE id = ?");
            $stmt->execute([$id]);
            
            // Delete from utilisateurs
            $stmt = $pdo->prepare("DELETE FROM utilisateurs WHERE id = ?");
            $stmt->execute([$teacher["utilisateur_id"]]);
            
            $response["success"] = 1;
            $response["message"] = "Teacher deleted successfully";
        } else {
            $response["success"] = 0;
            $response["message"] = "Teacher not found";
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "Teacher id required (use ?id=1 in URL)";
    }
    echo json_encode($response);
}
?>