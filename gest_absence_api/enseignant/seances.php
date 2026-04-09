<?php
include("../config/database.php");
$id_prof = $_GET['id'] ?? 0;

$stmt = $pdo->prepare("SELECT s.*, c.nom as classe_nom, m.nom as matiere_nom 
                       FROM seances s
                       JOIN classes c ON s.classe_id = c.id
                       JOIN matieres m ON s.matiere_id = m.id
                       WHERE s.enseignant_id = ?");
$stmt->execute([$id_prof]);
echo json_encode($stmt->fetchAll());