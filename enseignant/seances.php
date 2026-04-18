<?php
include("../config/db_connect.php");

// This ID now represents the LOGGED-IN USER (utilisateur_id), not the enseignant_id
$utilisateur_id = $_GET['id'] ?? 0;

// FIX: Join the 'enseignants' table so we can match by 'utilisateur_id'
$sql = "SELECT s.*, c.nom as classe_nom, m.nom as matiere_nom 
        FROM seances s
        JOIN classes c ON s.classe_id = c.id
        JOIN matieres m ON s.matiere_id = m.id
        JOIN enseignants e ON s.enseignant_id = e.id
        WHERE e.utilisateur_id = ?
        ORDER BY s.date_seance DESC, s.heure_debut ASC";

$stmt = $pdo->prepare($sql);
$stmt->execute([$utilisateur_id]);
echo json_encode($stmt->fetchAll());