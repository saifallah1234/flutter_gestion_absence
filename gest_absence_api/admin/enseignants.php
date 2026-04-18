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
    
    // Récupérer l'ID soit de l'URL soit du body
    $id = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
    
    if ($id) {
        // Get utilisateur_id from enseignant
        $stmt = $pdo->prepare("SELECT utilisateur_id FROM enseignants WHERE id = ?");
        $stmt->execute([$id]);
        $teacher = $stmt->fetch();
        
        if ($teacher) {
            $pdo->beginTransaction();
            
            // Update utilisateurs
            if (isset($data["nom"]) || isset($data["prenom"]) || isset($data["email"])) {
                $updateFields = [];
                $params = [];
                
                if (isset($data["nom"])) {
                    $updateFields[] = "nom = ?";
                    $params[] = $data["nom"];
                }
                if (isset($data["prenom"])) {
                    $updateFields[] = "prenom = ?";
                    $params[] = $data["prenom"];
                }
                if (isset($data["email"])) {
                    $updateFields[] = "email = ?";
                    $params[] = $data["email"];
                }
                
                if (!empty($updateFields)) {
                    $params[] = $teacher["utilisateur_id"];
                    $sql = "UPDATE utilisateurs SET " . implode(", ", $updateFields) . " WHERE id = ?";
                    $stmt = $pdo->prepare($sql);
                    $stmt->execute($params);
                }
            }
            
            // Update specialite if provided
            if (isset($data["specialite"])) {
                $sql2 = "UPDATE enseignants SET specialite = ? WHERE id = ?";
                $stmt2 = $pdo->prepare($sql2);
                $stmt2->execute([$data["specialite"], $id]);
            }
            
            $pdo->commit();
            
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
        $stmt = $pdo->prepare("SELECT utilisateur_id FROM enseignants WHERE id = ?");
        $stmt->execute([$id]);
        $teacher = $stmt->fetch();
        
        if ($teacher) {
            try {
                $pdo->beginTransaction();
                
                // 1. D'abord supprimer les absences liées aux séances de cet enseignant
                $stmt = $pdo->prepare("
                    DELETE a FROM absences a 
                    INNER JOIN seances s ON a.seance_id = s.id 
                    WHERE s.enseignant_id = ?
                ");
                $stmt->execute([$id]);
                
                // 2. Ensuite supprimer les séances de cet enseignant
                $stmt = $pdo->prepare("DELETE FROM seances WHERE enseignant_id = ?");
                $stmt->execute([$id]);
                
                // 3. Supprimer l'enseignant
                $stmt = $pdo->prepare("DELETE FROM enseignants WHERE id = ?");
                $stmt->execute([$id]);
                
                // 4. Supprimer l'utilisateur
                $stmt = $pdo->prepare("DELETE FROM utilisateurs WHERE id = ?");
                $stmt->execute([$teacher["utilisateur_id"]]);
                
                $pdo->commit();
                
                $response["success"] = 1;
                $response["message"] = "Enseignant supprimé avec succès (séances et absences associées également supprimées)";
                
            } catch (Exception $e) {
                $pdo->rollBack();
                $response["success"] = 0;
                $response["message"] = "Erreur lors de la suppression: " . $e->getMessage();
            }
        } else {
            $response["success"] = 0;
            $response["message"] = "Enseignant non trouvé";
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "ID enseignant requis (utilisez ?id=1 dans l'URL)";
    }
    echo json_encode($response);
}
// Méthode non supportée
else {
    $response["success"] = 0;
    $response["message"] = "Method not allowed";
    echo json_encode($response);
}
?>