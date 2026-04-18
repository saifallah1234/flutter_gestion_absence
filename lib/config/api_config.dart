const String baseUrl = 'http://10.0.2.2/gest_absence_api'; // For emulator
 //const String baseUrl = 'http://localhost/gest_absence_api'; // For Chrome
// const String baseUrl = 'http://192.168.1.100/gest_absence_api'; // For real phone

class ApiEndpoints {
  // Auth
  static const String login = '$baseUrl/auth/login.php';
  
  // Admin
  static const String adminEtudiants = '$baseUrl/admin/etudiants.php';
  static const String adminEnseignants = '$baseUrl/admin/enseignants.php';
  static const String adminClasses = '$baseUrl/admin/classes.php';
  static const String adminSeances = '$baseUrl/admin/seances.php';
  static const String adminMatieres = "$baseUrl/admin/matieres.php";

  
  
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