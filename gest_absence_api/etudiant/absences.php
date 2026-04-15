<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json");

include("../config/database.php");

$response = array();

if (!isset($pdo)) {
    echo json_encode(["success" => 0, "message" => "Database connection failed"]);
    exit;
}

$etudiant_id = isset($_GET['id']) ? intval($_GET['id']) : 0;

if (!$etudiant_id) {
    $response["success"] = 0;
    $response["message"] = "Student id required";
    echo json_encode($response);
    exit;
}

// Get student info
$sql = "SELECT u.id, u.nom, u.prenom, u.email, c.nom as classe_nom, c.id as classe_id
        FROM utilisateurs u 
        JOIN etudiants e ON u.id = e.utilisateur_id 
        JOIN classes c ON e.classe_id = c.id 
        WHERE e.id = ?";
$stmt = $pdo->prepare($sql);
$stmt->execute([$etudiant_id]);
$student = $stmt->fetch(PDO::FETCH_ASSOC);

// Get student's class ID
$classe_id = $student['classe_id'];

// FIRST: Get ALL subjects for this class (from seances)
$sql = "SELECT DISTINCT m.id, m.nom as matiere
        FROM matieres m
        JOIN seances s ON m.id = s.matiere_id
        WHERE s.classe_id = ?
        ORDER BY m.nom";
$stmt = $pdo->prepare($sql);
$stmt->execute([$classe_id]);
$all_subjects = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Get total seances per subject (total hours)
$sql = "SELECT m.id, m.nom as matiere, COUNT(s.id) as total_seances
        FROM matieres m
        JOIN seances s ON m.id = s.matiere_id
        WHERE s.classe_id = ?
        GROUP BY m.id, m.nom";
$stmt = $pdo->prepare($sql);
$stmt->execute([$classe_id]);
$total_seances_by_subject = [];
foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $row) {
    $total_seances_by_subject[$row['matiere']] = $row['total_seances'];
}

// Get student's absences
$sql = "SELECT a.statut, s.date_seance, s.heure_debut, m.nom as matiere, m.id as matiere_id
        FROM absences a 
        JOIN seances s ON a.seance_id = s.id 
        JOIN matieres m ON s.matiere_id = m.id 
        WHERE a.etudiant_id = ? 
        ORDER BY s.date_seance DESC";
$stmt = $pdo->prepare($sql);
$stmt->execute([$etudiant_id]);
$absences = $stmt->fetchAll(PDO::FETCH_ASSOC);

// Calculate statistics PER SUBJECT including ALL subjects
$subject_stats = [];
$total_present_all = 0;
$total_absent_all = 0;
$total_seances_all = 0;

foreach ($all_subjects as $subject) {
    $matiere = $subject['matiere'];
    $total_seances = $total_seances_by_subject[$matiere] ?? 0;
    
    // Count student's records for this subject
    $present = 0;
    $absent = 0;
    
    foreach ($absences as $absence) {
        if ($absence['matiere'] == $matiere) {
            if ($absence['statut'] == 'present') {
                $present++;
            } else {
                $absent++;
            }
        }
    }
    
    $total_present_all += $present;
    $total_absent_all += $absent;
    $total_seances_all += $total_seances;
    
    // Calculate rates based on TOTAL seances (not just recorded ones)
    $attendance_rate = $total_seances > 0 ? round(($present / $total_seances) * 100, 2) : 100;
    $absence_rate = $total_seances > 0 ? round(($absent / $total_seances) * 100, 2) : 0;
    
    $subject_stats[] = [
        'matiere' => $matiere,
        'total_seances' => $total_seances,
        'present' => $present,
        'absent' => $absent,
        'attendance_rate' => $attendance_rate,
        'absence_rate' => $absence_rate,
        'status' => $absence_rate > 20 ? 'danger' : ($absence_rate > 10 ? 'warning' : 'good')
    ];
}

// Overall rates
$overall_attendance_rate = $total_seances_all > 0 ? round(($total_present_all / $total_seances_all) * 100, 2) : 100;
$overall_absence_rate = $total_seances_all > 0 ? round(($total_absent_all / $total_seances_all) * 100, 2) : 0;

// Generate warnings
$warnings = [];
$critical_warnings = [];

foreach ($subject_stats as $subject) {
    $absence_rate = $subject['absence_rate'];
    $matiere = $subject['matiere'];
    
    if ($absence_rate > 20) {
        $critical_warnings[] = [
            'type' => 'subject_critical',
            'matiere' => $matiere,
            'absence_rate' => $absence_rate,
            'message' => "⚠️ CRITICAL: $absence_rate% d'absences en $matiere (limite: 20%)"
        ];
    } elseif ($absence_rate > 10) {
        $warnings[] = [
            'type' => 'subject_warning',
            'matiere' => $matiere,
            'absence_rate' => $absence_rate,
            'message' => "⚠️ Attention: $absence_rate% d'absences en $matiere (limite: 20%)"
        ];
    }
}

// Overall warning
if ($overall_absence_rate > 10) {
    $critical_warnings[] = [
        'type' => 'overall_critical',
        'absence_rate' => $overall_absence_rate,
        'message' => "🚨 ALERTE: $overall_absence_rate% d'absences totales (limite: 10%)"
    ];
} elseif ($overall_absence_rate > 5) {
    $warnings[] = [
        'type' => 'overall_warning',
        'absence_rate' => $overall_absence_rate,
        'message' => "📢 Attention: $overall_absence_rate% d'absences totales (limite: 10%)"
    ];
}

$response["success"] = 1;
$response["data"] = [
    'student' => $student,
    'absences_list' => $absences,
    'statistics' => [
        'total_seances' => $total_seances_all,
        'present' => $total_present_all,
        'absent' => $total_absent_all,
        'overall_attendance_rate' => $overall_attendance_rate,
        'overall_absence_rate' => $overall_absence_rate,
        'subject_stats' => $subject_stats
    ],
    'warnings' => $warnings,
    'critical_warnings' => $critical_warnings,
    'limits' => [
        'max_absence_per_subject' => 20,
        'max_absence_total' => 10
    ]
];

echo json_encode($response);
?>