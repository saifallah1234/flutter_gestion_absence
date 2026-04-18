// lib/models/absence.dart
class Absence {
  final int? id;
  final int seanceId;
  final int etudiantId;
  final String statut; // 'present' ou 'absent'

  Absence({
    this.id,
    required this.seanceId,
    required this.etudiantId,
    required this.statut,
  });

  // Pour créer une Absence depuis JSON (GET)
  factory Absence.fromJson(Map<String, dynamic> json) {
    return Absence(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      seanceId: json['seance_id'] is int 
          ? json['seance_id'] 
          : int.tryParse(json['seance_id'].toString()) ?? 0,
      etudiantId: json['etudiant_id'] is int 
          ? json['etudiant_id'] 
          : int.tryParse(json['etudiant_id'].toString()) ?? 0,
      statut: json['statut']?.toString().toLowerCase() ?? 'absent',
    );
  }

  // Pour envoyer vers l'API (POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'seance_id': seanceId,
      'etudiant_id': etudiantId,
      'statut': statut,
    };
  }
  
  // Pour l'envoi groupé (appel)
  Map<String, dynamic> toAppelJson() {
    return {
      'etudiant_id': etudiantId,
      'statut': statut,
    };
  }
  

  @override
  String toString() {
    return 'Absence(id: $id, seanceId: $seanceId, etudiantId: $etudiantId, statut: $statut)';
  }
}