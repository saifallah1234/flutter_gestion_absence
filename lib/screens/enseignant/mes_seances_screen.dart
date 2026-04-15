import 'package:flutter/material.dart';
import '../../models/utilisateur.dart';
import '../../models/seance.dart';
import '../../services/api_service.dart';
import 'appel_screen.dart'; // Import de la page d'appel

class MesSeancesScreen extends StatefulWidget {
  final Utilisateur user;

  const MesSeancesScreen({super.key, required this.user});

  @override
  State<MesSeancesScreen> createState() => _MesSeancesScreenState();
}

class _MesSeancesScreenState extends State<MesSeancesScreen> {
  late Future<List<Seance>> _seancesFuture;

  @override
  void initState() {
    super.initState();
    _loadSeances();
  }

  void _loadSeances() {
    _seancesFuture = ApiService.getSeancesEnseignant(widget.user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Séances'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Seance>>(
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
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            seance.matiereNom ?? 'Matière',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          Chip(
                            label: Text(seance.classeNom ?? 'Classe'),
                            backgroundColor: const Color(0xFFE8E7F2),
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
                          onPressed: () {
                            // Navigation vers la page d'appel en passant la séance
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
    );
  }
}