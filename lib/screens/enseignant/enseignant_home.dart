import 'package:flutter/material.dart';
import '../../models/utilisateur.dart';
import '../../models/seance.dart';
import '../../services/api_service.dart';
import 'appel_screen.dart';

class EnseignantHomeScreen extends StatefulWidget {
  final Utilisateur user;

  const EnseignantHomeScreen({super.key, required this.user});

  @override
  State<EnseignantHomeScreen> createState() => _EnseignantHomeScreenState();
}

class _EnseignantHomeScreenState extends State<EnseignantHomeScreen> {
  late Future<List<Seance>> _seancesFuture;

  @override
  void initState() {
    super.initState();
    _loadSeances();
  }

  void _loadSeances() {
    // Appelle l'API pour récupérer uniquement les séances de ce prof
    _seancesFuture = ApiService.getSeancesEnseignant(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Séances'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Retour à la page de connexion
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de bienvenue
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A237E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, Prof. ${widget.user.prenom} ${widget.user.nom}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Voici vos prochaines classes.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          
          // Liste des séances
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _loadSeances();
                });
              },
              child: FutureBuilder<List<Seance>>(
                future: _seancesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Aucune séance planifiée.'));
                  }

                  final seances = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: seances.length,
                    itemBuilder: (context, index) {
                      final seance = seances[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    seance.matiereNom ?? 'Matière inconnue',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(seance.classeNom ?? 'Classe'),
                                    backgroundColor: const Color(0xFFE8E7F2),
                                    labelStyle: const TextStyle(
                                      color: Color(0xFF1A237E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(seance.dateSeance),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text('${seance.heureDebut} - ${seance.heureFin}'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.checklist),
                                  label: const Text("Faire l'appel"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE8E7F2),
                                    foregroundColor: const Color(0xFF1A237E),
                                    elevation: 0,
                                  ),
                                  onPressed: () {
                                    // TODO: Naviguer vers la page d'appel (absences.dart)
                                    // en lui passant l'ID de la séance et l'ID de la classe
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AppelScreen(seance: seance),
                                            ),
                                          );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}