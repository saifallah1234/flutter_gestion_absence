class Etudiant {
  final int id; 
  final int utilisateurId;
  final String nom; 
  final String prenom; 
  final int classeId;

  Etudiant({
    required this.id, 
    required this.utilisateurId, 
    required this.nom, 
    required this.prenom, 
    required this.classeId
  });

  factory Etudiant.fromJson(Map<String, dynamic> json) {
    return Etudiant(
      id: int.parse(json['id'].toString()),
      utilisateurId: int.parse(json['utilisateur_id'].toString()),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      classeId: int.parse(json['classe_id'].toString()),
    );
  }
}