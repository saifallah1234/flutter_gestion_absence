<?php
include("../config/database.php");
$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        $stmt = $pdo->query("SELECT u.id, u.nom, u.prenom, u.email, e.specialite 
                             FROM utilisateurs u 
                             JOIN enseignants e ON u.id = e.utilisateur_id");
        echo json_encode($stmt->fetchAll());
        break;

    case 'POST':
        // Support both $_POST and JSON input
        $data = json_decode(file_get_contents("php://input"), true) ?: $_POST;
        
        $pdo->beginTransaction();
        try {
            $sqlU = "INSERT INTO utilisateurs (nom, prenom, email, password, role) VALUES (?, ?, ?, ?, 'enseignant')";
            $stmtU = $pdo->prepare($sqlU);
            $stmtU->execute([$data['nom'], $data['prenom'], $data['email'], password_hash($data['password'], PASSWORD_DEFAULT)]);
            
            $userId = $pdo->lastInsertId();
            
            $sqlE = "INSERT INTO enseignants (utilisateur_id, specialite) VALUES (?, ?)";
            $stmtE = $pdo->prepare($sqlE);
            $stmtE->execute([$userId, $data['specialite']]);
            
            $pdo->commit();
            echo json_encode(["status" => "Success"]);
        } catch (Exception $e) {
            $pdo->rollBack();
            echo json_encode(["status" => "Error", "message" => $e->getMessage()]);
        }
        case 'PUT':
        // Get the data (usually sent as JSON for PUT requests)
        $data = json_decode(file_get_contents("php://input"), true) ?: $_POST;
        
        if (!isset($data['id'])) {
            echo json_encode(["status" => "Error", "message" => "Missing ID"]);
            break;
        }

        $pdo->beginTransaction();
        try {
            // 1. Update the base user info
            $sqlU = "UPDATE utilisateurs SET nom = ?, prenom = ?, email = ? WHERE id = ?";
            $stmtU = $pdo->prepare($sqlU);
            $stmtU->execute([$data['nom'], $data['prenom'], $data['email'], $data['id']]);
            
            // 2. Update the teacher-specific info (specialty)
            $sqlE = "UPDATE enseignants SET specialite = ? WHERE utilisateur_id = ?";
            $stmtE = $pdo->prepare($sqlE);
            $stmtE->execute([$data['specialite'], $data['id']]);
            
            $pdo->commit();
            echo json_encode(["status" => "Success", "message" => "Teacher updated"]);
        } catch (Exception $e) {
            $pdo->rollBack();
            echo json_encode(["status" => "Error", "message" => $e->getMessage()]);
        }
        break;

    case 'DELETE':
        // Retrieve ID from the URL (e.g., enseignants.php?id=5)
        $id = $_GET['id'] ?? null;

        if ($id) {
            // Because of ON DELETE CASCADE in your SQL, 
            // deleting from 'utilisateurs' automatically removes the 'enseignants' entry.
            $stmt = $pdo->prepare("DELETE FROM utilisateurs WHERE id = ?");
            if ($stmt->execute([$id])) {
                echo json_encode(["status" => "Success", "message" => "Teacher deleted"]);
            } else {
                echo json_encode(["status" => "Error", "message" => "Delete failed"]);
            }
        } else {
            echo json_encode(["status" => "Error", "message" => "ID is required"]);
        }
        break;
        
    default:
        echo json_encode(["status" => "Error", "message" => "Method not allowed"]);
        break;
}