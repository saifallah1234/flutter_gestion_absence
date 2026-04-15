class Absence {
  final int? id;
  final int seanceId;
  final int etudiantId;
  final String statut; // Must be strictly 'present' or 'absent'

  Absence({
    this.id, 
    required this.seanceId, 
    required this.etudiantId, 
    required this.statut
  });

  // Used to convert the Dart object back into JSON for the POST request
  Map<String, dynamic> toJson() {
    return {
      'etudiant_id': etudiantId,
      'statut': statut,
    };
  }
}