class EtudiantProfile {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String classe;

  EtudiantProfile({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.classe,
  });

  factory EtudiantProfile.fromJson(Map<String, dynamic> json) {
    return EtudiantProfile(
      id: json['id'] ?? 0,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      classe: json['classe'] ?? '',
    );
  }
}