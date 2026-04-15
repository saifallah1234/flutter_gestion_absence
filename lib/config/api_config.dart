const String baseUrl = 'http://localhost/gest_absence_api'; // For emulator
// const String baseUrl = 'http://localhost/gest_absence_api'; // For Chrome
// const String baseUrl = 'http://192.168.1.100/gest_absence_api'; // For real phone

class ApiEndpoints {
  // Auth
  static const String login = '$baseUrl/auth/login.php';
  
  // Admin
  static const String etudiants = '$baseUrl/admin/etudiants.php';
  static const String enseignants = '$baseUrl/admin/enseignants.php';
  static const String classes = '$baseUrl/admin/classes.php';
  static const String seances = '$baseUrl/admin/seances.php';
  
  // Enseignant
  static const String enseignantSeances = '$baseUrl/enseignant/seances.php';
  static const String enseignantAbsences = '$baseUrl/enseignant/absences.php';
  static const String studentsByClass = '$baseUrl/enseignant/students_by_class.php';
  
  // Etudiant
  static const String etudiantProfil = '$baseUrl/etudiant/profil.php';
  static const String etudiantAbsences = '$baseUrl/etudiant/absences.php';
  static const String saveDevice = '$baseUrl/etudiant/save_device.php';
  static const String notifications = '$baseUrl/etudiant/notifications.php';
}