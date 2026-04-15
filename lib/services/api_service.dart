// lib/services/api_service.dart - Version corrigée avec baseUrl
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/utilisateur.dart';
import '../models/seance.dart';
import '../models/absence.dart';
import '../models/etudiant.dart';

class ApiService {
  static const Map<String, String> jsonHeaders = {
    'Content-Type': 'application/json',
  };

  // ==========================================
  // AUTHENTICATION
  // ==========================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(ApiEndpoints.login);
    try {
      final response = await http.post(
        url,
        headers: jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode != 200) {
        return {
          'success': 0,
          'message': 'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Erreur'}',
        };
      }

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'success': 0,
        'message': 'Réponse du serveur invalide',
      };
    } catch (e) {
      return {
        'success': 0,
        'message': 'Erreur serveur: $e',
      };
    }
  }

  // ==========================================
  // ETUDIANTS ENDPOINTS
  // ==========================================
  static Future<List<Etudiant>> getEtudiantsByClasse(int classeId) async {
    final url = Uri.parse('${ApiEndpoints.enseignantAbsences}?classe_id=$classeId');
    try {
      final response = await http.get(url, headers: jsonHeaders);
      print('Statut HTTP: ${response.statusCode}');
      print('Réponse brute PHP: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((json) => Etudiant.fromJson(json)).toList();
      }

      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        print('Erreur API: ${decoded['message']}');
      }
      return [];
    } catch (e) {
      print('Erreur fatale Flutter: $e');
      throw Exception('Impossible de charger les étudiants');
    }
  }

  // ==========================================
  // ENSEIGNANT ENDPOINTS
  // ==========================================
  static Future<List<Seance>> getSeancesEnseignant(int utilisateurId) async {
    final url = Uri.parse('${ApiEndpoints.enseignantSeances}?id=$utilisateurId');
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((json) => Seance.fromJson(json)).toList();
      }

      if (decoded is Map<String, dynamic> && decoded.containsKey('message')) {
        print('Erreur API: ${decoded['message']}');
      }
      return [];
    } catch (e) {
      print('Erreur fatale Flutter: $e');
      throw Exception('Impossible de charger les séances');
    }
  }

  static Future<bool> soumettreAppel(int seanceId, List<Absence> appel) async {
    final url = Uri.parse(ApiEndpoints.enseignantAbsences);
    try {
      final response = await http.post(
        url,
        headers: jsonHeaders,
        body: jsonEncode({
          'seance_id': seanceId,
          'appel': appel.map((a) => a.toJson()).toList(),
        }),
      );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        return data['success'] == 1 || data['status'] == 'Success' || data['status'] == 'Attendance updated';
      }

      return false;
    } catch (e) {
      print('Erreur soumettreAppel: $e');
      return false;
    }
  }

  // ==========================================
  // ETUDIANT ENDPOINTS
  // ==========================================
  static Future<Map<String, dynamic>> getEtudiantDashboard(int etudiantId) async {
    final url = Uri.parse('${ApiEndpoints.etudiantAbsences}?id=$etudiantId');
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> getEtudiantProfil(int etudiantId) async {
    final url = Uri.parse('${ApiEndpoints.etudiantProfil}?id=$etudiantId');
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  // ==========================================
  // ADMIN ENDPOINTS - ETUDIANTS
  // ==========================================
  static Future<Map<String, dynamic>> getAdminEtudiants() async {
    final url = Uri.parse(ApiEndpoints.adminEtudiants);
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> ajouterEtudiant(Map<String, dynamic> data) async {
    final url = Uri.parse(ApiEndpoints.adminEtudiants);
    try {
      final response = await http.post(
        url,
        headers: jsonHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> modifierEtudiant(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiEndpoints.adminEtudiants}?id=$id');
    try {
      final response = await http.put(
        url,
        headers: jsonHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> supprimerEtudiant(int id) async {
    final url = Uri.parse('${ApiEndpoints.adminEtudiants}?id=$id');
    try {
      final response = await http.delete(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  // ==========================================
  // ADMIN ENDPOINTS - ENSEIGNANTS
  // ==========================================
  static Future<Map<String, dynamic>> getAdminEnseignants() async {
    final url = Uri.parse(ApiEndpoints.adminEnseignants);
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> ajouterEnseignant(Map<String, dynamic> data) async {
    final url = Uri.parse(ApiEndpoints.adminEnseignants);
    try {
      final response = await http.post(
        url,
        headers: jsonHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> modifierEnseignant(int id, Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiEndpoints.adminEnseignants}?id=$id');
    try {
      final response = await http.put(
        url,
        headers: jsonHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> supprimerEnseignant(int id) async {
    final url = Uri.parse('${ApiEndpoints.adminEnseignants}?id=$id');
    try {
      final response = await http.delete(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  // ==========================================
  // ADMIN ENDPOINTS - CLASSES
  // ==========================================
  static Future<Map<String, dynamic>> getAdminClasses() async {
    final url = Uri.parse(ApiEndpoints.adminClasses);
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> ajouterClasse(Map<String, dynamic> data) async {
    final url = Uri.parse(ApiEndpoints.adminClasses);
    try {
      final response = await http.post(
        url,
        headers: jsonHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  // ==========================================
  // ADMIN ENDPOINTS - SEANCES
  // ==========================================
  static Future<Map<String, dynamic>> getAdminSeances() async {
    final url = Uri.parse(ApiEndpoints.adminSeances);
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> getSeanceFormData() async {
    final url = Uri.parse('${ApiEndpoints.adminSeances}?lists=true');
    try {
      final response = await http.get(url, headers: jsonHeaders);
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  static Future<Map<String, dynamic>> ajouterSeance(Map<String, dynamic> data) async {
    final url = Uri.parse(ApiEndpoints.adminSeances);
    try {
      final response = await http.post(
        url,
        headers: jsonHeaders,
        body: jsonEncode(data),
      );
      if (response.statusCode != 200) {
        return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
      }
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': 0, 'message': 'Erreur: $e'};
    }
  }

  // ==========================================
  // NOTIFICATIONS ENDPOINTS
  // ==========================================
  // Dans api_service.dart, corriger ces méthodes :

static Future<Map<String, dynamic>> getNotifications(int userId, String userType) async {
  // Correction : utiliser le bon chemin
  final url = Uri.parse('$baseUrl/etudiant/notifications.php?user_id=$userId&user_type=$userType');
  try {
    final response = await http.get(url, headers: jsonHeaders);
    if (response.statusCode != 200) {
      return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': 0, 'message': 'Erreur: $e'};
  }
}

static Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
  final url = Uri.parse('$baseUrl/etudiant/notifications.php');
  try {
    final response = await http.put(
      url,
      headers: jsonHeaders,
      body: jsonEncode({'id': notificationId, 'is_read': 1}),
    );
    if (response.statusCode != 200) {
      return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': 0, 'message': 'Erreur: $e'};
  }
}

static Future<Map<String, dynamic>> markAllNotificationsAsRead(int userId, String userType) async {
  final url = Uri.parse('$baseUrl/etudiant/notifications.php?action=mark_all');
  try {
    final response = await http.put(
      url,
      headers: jsonHeaders,
      body: jsonEncode({'user_id': userId, 'user_type': userType}),
    );
    if (response.statusCode != 200) {
      return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': 0, 'message': 'Erreur: $e'};
  }
}

static Future<Map<String, dynamic>> getNotificationStats(int userId, String userType) async {
  final url = Uri.parse('$baseUrl/etudiant/notifications.php?action=stats&user_id=$userId&user_type=$userType');
  try {
    final response = await http.get(url, headers: jsonHeaders);
    if (response.statusCode != 200) {
      return {'success': 0, 'message': 'HTTP ${response.statusCode}'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': 0, 'message': 'Erreur: $e'};
  }
}
}