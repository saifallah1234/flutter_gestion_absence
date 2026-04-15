import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/utilisateur.dart';
import '../models/seance.dart';
import '../models/absence.dart';
import '../models/etudiant.dart';

class ApiService {
  // ==========================================
  // AUTHENTICATION
  // ==========================================
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/auth/login.php');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'status': 'Error', 'message': 'Erreur serveur: $e'};
    }
  }

  // ==========================================
  // ETUDIANTS ENDPOINTS
  // ==========================================
 static Future<List<Etudiant>> getEtudiantsByClasse(int classeId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/enseignant/absences.php?classe_id=$classeId');
    try {
      final response = await http.get(url, headers: ApiConfig.headers);
      
      // -- AJOUTS POUR LE DEBUG --
      print('Statut HTTP: ${response.statusCode}');
      print('Réponse brute PHP: ${response.body}');
      // --------------------------

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // On vérifie si la réponse est bien une liste (et pas un message d'erreur {"status": "Error"})
        if (decoded is List) {
          return decoded.map((json) => Etudiant.fromJson(json)).toList();
        } else {
          print('Erreur renvoyée par PHP : $decoded');
          return [];
        }
      }
      return [];
    } catch (e) {
      // On affiche la VRAIE erreur Flutter dans la console
      print('Erreur fatale Flutter: $e'); 
      throw Exception('Erreur: $e');
    }
  }

  // ==========================================
  // ENSEIGNANT ENDPOINTS
  // ==========================================
  static Future<List<Seance>> getSeancesEnseignant(int utilisateurId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/enseignant/seances.php?id=$utilisateurId');
    try {
      final response = await http.get(url, headers: ApiConfig.headers);
      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        return data.map((json) => Seance.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Impossible de charger les séances');
    }
  }

  static Future<bool> soumettreAppel(int seanceId, List<Absence> appel) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/enseignant/absences.php');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.headers,
        body: jsonEncode({
          'seance_id': seanceId,
          'appel': appel.map((a) => a.toJson()).toList(),
        }),
      );
      final data = jsonDecode(response.body);
      return data['status'] == 'Success' || data['status'] == 'Attendance updated';
    } catch (e) {
      return false;
    }
  }
}