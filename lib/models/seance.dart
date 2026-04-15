class Seance {
  final int id;
  final int enseignantId;
  final int classeId;
  final int matiereId;
  final String dateSeance;
  final String heureDebut;
  final String heureFin;
  
  // Fields populated by SQL JOINs
  final String? classeNom;
  final String? matiereNom;

  Seance({
    required this.id,
    required this.enseignantId,
    required this.classeId,
    required this.matiereId,
    required this.dateSeance,
    required this.heureDebut,
    required this.heureFin,
    this.classeNom,
    this.matiereNom,
  });

  factory Seance.fromJson(Map<String, dynamic> json) {
    return Seance(
      id: int.parse(json['id'].toString()),
      enseignantId: int.parse(json['enseignant_id'].toString()),
      classeId: int.parse(json['classe_id'].toString()),
      matiereId: int.parse(json['matiere_id'].toString()),
      dateSeance: json['date_seance'],
      heureDebut: json['heure_debut'],
      heureFin: json['heure_fin'],
      classeNom: json['classe_nom'], 
      matiereNom: json['matiere_nom'], 
    );
  }
}