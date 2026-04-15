<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

include("../config/db_connect.php");

$response = array();

if (!isset($pdo)) {
    echo json_encode(["success" => 0, "message" => "Database connection failed"]);
    exit;
}

// Get JSON input
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data["email"]) || !isset($data["password"])) {
    $response["success"] = 0;
    $response["message"] = "Email and password required";
    echo json_encode($response);
    exit;
}

$email = $data["email"];
$password = $data["password"];

// Find user by email and password
$sql = "SELECT id, nom, prenom, email, role FROM utilisateurs WHERE email = ? AND password = ?";
$stmt = $pdo->prepare($sql);
$stmt->execute([$email, $password]);
$user = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$user) {
    $response["success"] = 0;
    $response["message"] = "Invalid email or password";
    echo json_encode($response);
    exit;
}

// Get additional info based on role
$additional_data = array();

if ($user["role"] == "etudiant") {
    // Get student info (classe)
    $stmt = $pdo->prepare("SELECT e.id as etudiant_id, c.id as classe_id, c.nom as classe_nom 
                           FROM etudiants e 
                           JOIN classes c ON e.classe_id = c.id 
                           WHERE e.utilisateur_id = ?");
    $stmt->execute([$user["id"]]);
    $student = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($student) {
        $additional_data["etudiant_id"] = $student["etudiant_id"];
        $additional_data["classe_id"] = $student["classe_id"];
        $additional_data["classe_nom"] = $student["classe_nom"];
    }
    
} elseif ($user["role"] == "enseignant") {
    // Get teacher info
    $stmt = $pdo->prepare("SELECT id as enseignant_id, specialite FROM enseignants WHERE utilisateur_id = ?");
    $stmt->execute([$user["id"]]);
    $teacher = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($teacher) {
        $additional_data["enseignant_id"] = $teacher["enseignant_id"];
        $additional_data["specialite"] = $teacher["specialite"];
    }
    
} elseif ($user["role"] == "admin") {
    // Admin doesn't need extra info
    $additional_data["is_admin"] = true;
}

$response["success"] = 1;
$response["message"] = "Login successful";
$response["data"] = array_merge($user, $additional_data);

echo json_encode($response);
?>