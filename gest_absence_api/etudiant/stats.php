<?php
// etudiant/stats.php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Gérer la requête OPTIONS (preflight CORS)
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include("../config/db_connect.php");

$etudiant_id = isset($_GET['id']) ? intval($_GET['id']) : 0;

if (!$etudiant_id) {
    echo json_encode(["success" => 0, "message" => "ID requis"]);
    exit;
}

// Statistiques globales (corrigé pour ne pas utiliser 'justifie')
$sql = "SELECT 
            COUNT(DISTINCT s.id) as total_seances,
            SUM(CASE WHEN a.statut = 'present' THEN 1 ELSE 0 END) as total_present,
            SUM(CASE WHEN a.statut = 'absent' THEN 1 ELSE 0 END) as total_absent,
            ROUND(AVG(CASE WHEN a.statut = 'present' THEN 100 ELSE 0 END), 1) as attendance_rate,
            ROUND(AVG(CASE WHEN a.statut = 'absent' THEN 100 ELSE 0 END), 1) as absence_rate
        FROM etudiants e
        LEFT JOIN absences a ON e.id = a.etudiant_id
        LEFT JOIN seances s ON a.seance_id = s.id
        WHERE e.id = ?";

$stmt = $pdo->prepare($sql);
$stmt->execute([$etudiant_id]);
$stats = $stmt->fetch(PDO::FETCH_ASSOC);

// Statistiques par matière
$sqlMat = "SELECT 
                m.nom as matiere,
                COUNT(s.id) as total,
                SUM(CASE WHEN a.statut = 'present' THEN 1 ELSE 0 END) as presents,
                ROUND(AVG(CASE WHEN a.statut = 'present' THEN 100 ELSE 0 END), 1) as attendance_rate
            FROM seances s
            JOIN matieres m ON s.matiere_id = m.id
            JOIN absences a ON s.id = a.seance_id
            WHERE a.etudiant_id = ?
            GROUP BY m.id, m.nom
            ORDER BY attendance_rate ASC";

$stmtMat = $pdo->prepare($sqlMat);
$stmtMat->execute([$etudiant_id]);
$byMatiere = $stmtMat->fetchAll(PDO::FETCH_ASSOC);

// Données mensuelles pour le graphique
$sqlMonth = "SELECT 
                DATE_FORMAT(s.date_seance, '%b') as month,
                ROUND(AVG(CASE WHEN a.statut = 'present' THEN 100 ELSE 0 END), 1) as rate
            FROM seances s
            JOIN absences a ON s.id = a.seance_id
            WHERE a.etudiant_id = ? 
                AND s.date_seance >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
            GROUP BY DATE_FORMAT(s.date_seance, '%Y-%m'), DATE_FORMAT(s.date_seance, '%b')
            ORDER BY MIN(s.date_seance)";

$stmtMonth = $pdo->prepare($sqlMonth);
$stmtMonth->execute([$etudiant_id]);
$monthlyData = $stmtMonth->fetchAll(PDO::FETCH_ASSOC);

echo json_encode([
    "success" => 1,
    "data" => [
        "total_seances" => intval($stats['total_seances'] ?? 0),
        "total_present" => intval($stats['total_present'] ?? 0),
        "total_absent" => intval($stats['total_absent'] ?? 0),
        "attendance_rate" => floatval($stats['attendance_rate'] ?? 100),
        "absence_rate" => floatval($stats['absence_rate'] ?? 0),
        "by_matiere" => $byMatiere,
        "monthly_data" => $monthlyData
    ]
]);
?>