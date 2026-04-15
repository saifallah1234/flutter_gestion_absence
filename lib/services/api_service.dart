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
}
