<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE");

include("../config/db_connect.php");

$method = $_SERVER["REQUEST_METHOD"];
$response = array();

if (!isset($pdo)) {
    echo json_encode(["success" => 0, "message" => "Database connection failed"]);
    exit;
}

// GET 
if ($method == "GET") {
    $sql = "SELECT e.id, u.nom, u.prenom, u.email, c.nom as classe 
            FROM etudiants e 
            JOIN utilisateurs u ON e.utilisateur_id = u.id 
            JOIN classes c ON e.classe_id = c.id";
    
    $result = $pdo->query($sql);
    $students = $result->fetchAll(PDO::FETCH_ASSOC);
    
    $response["success"] = 1;
    $response["data"] = $students;
    echo json_encode($response);
}

// POST 
elseif ($method == "POST") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (isset($data["nom"]) && isset($data["prenom"]) && isset($data["email"]) && isset($data["password"]) && isset($data["classe_id"])) {
        
        $pdo->beginTransaction();
        
        $sql1 = "INSERT INTO utilisateurs (nom, prenom, email, password, role) VALUES (?, ?, ?, ?, 'etudiant')";
        $stmt1 = $pdo->prepare($sql1);
        $stmt1->execute([$data["nom"], $data["prenom"], $data["email"], $data["password"]]);
        $user_id = $pdo->lastInsertId();
        
        $sql2 = "INSERT INTO etudiants (utilisateur_id, classe_id) VALUES (?, ?)";
        $stmt2 = $pdo->prepare($sql2);
        $stmt2->execute([$user_id, $data["classe_id"]]);
        
        $pdo->commit();
        
        $response["success"] = 1;
        $response["message"] = "Student added successfully";
    } else {
        $response["success"] = 0;
        $response["message"] = "Missing fields: nom, prenom, email, password, classe_id";
    }
    echo json_encode($response);
}

// PUT
elseif ($method == "PUT") {
    $data = json_decode(file_get_contents("php://input"), true);
    
    // Récupérer l'ID soit de l'URL soit du body
    $id = isset($_GET['id']) ? $_GET['id'] : (isset($data['id']) ? $data['id'] : null);
    
    if ($id) {
        // Mettre à jour l'utilisateur
        if (isset($data["nom"]) && isset($data["prenom"]) && isset($data["email"])) {
            $sql = "UPDATE utilisateurs u 
                    JOIN etudiants e ON e.utilisateur_id = u.id 
                    SET u.nom = ?, u.prenom = ?, u.email = ? 
                    WHERE e.id = ?";
            $stmt = $pdo->prepare($sql);
            $stmt->execute([$data["nom"], $data["prenom"], $data["email"], $id]);
            
            // Mettre à jour la classe si fournie
            if (isset($data["classe_id"])) {
                $sql2 = "UPDATE etudiants SET classe_id = ? WHERE id = ?";
                $stmt2 = $pdo->prepare($sql2);
                $stmt2->execute([$data["classe_id"], $id]);
            }
            
            $response["success"] = 1;
            $response["message"] = "Student updated successfully";
        } else {
            $response["success"] = 0;
            $response["message"] = "Missing fields: nom, prenom, email";
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "Student id required";
    }
    echo json_encode($response);
}

// DELETE 
elseif ($method == "DELETE") {
    //get id from query not put a json body it wont work
    $id = isset($_GET['id']) ? $_GET['id'] : null;
    
    if ($id) {
        $stmt = $pdo->prepare("SELECT utilisateur_id FROM etudiants WHERE id = ?");
        $stmt->execute([$id]);
        $student = $stmt->fetch();
        
        if ($student) {
            // delete absences
            $stmt = $pdo->prepare("DELETE FROM absences WHERE etudiant_id = ?");
            $stmt->execute([$id]);
            
            // delete the student
            $stmt = $pdo->prepare("DELETE FROM etudiants WHERE id = ?");
            $stmt->execute([$id]);
            
            // delete the user
            $stmt = $pdo->prepare("DELETE FROM utilisateurs WHERE id = ?");
            $stmt->execute([$student["utilisateur_id"]]);
            
            $response["success"] = 1;
            $response["message"] = "Student deleted successfully";
        } else {
            $response["success"] = 0;
            $response["message"] = "Student not found";
        }
    } else {
        $response["success"] = 0;
        $response["message"] = "Student id required (use ?id=1 in URL)";
    }
    echo json_encode($response);
}
?>