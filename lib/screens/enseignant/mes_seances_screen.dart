// lib/screens/enseignant/mes_seances_screen.dart
import 'package:flutter/material.dart';
import '../../models/utilisateur.dart';
import '../../models/seance.dart';
import '../../services/api_service.dart';
import 'appel_screen.dart';

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
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        title: const Text(
          'Mes Séances',
          style: TextStyle(
            color: Color(0xFF000666),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000666)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
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
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Erreur: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _loadSeances());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune séance planifiée',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final seances = snapshot.data!;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: seances.length,
              itemBuilder: (context, index) {
                final seance = seances[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                seance.matiereNom ?? 'Matière',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF000666),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E7F2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                seance.classeNom ?? 'Classe',
                                style: const TextStyle(
                                  color: Color(0xFF1A237E),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, 
                                 size: 14, 
                                 color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              seance.dateSeance,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.access_time, 
                                 size: 14, 
                                 color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              '${seance.heureDebut} - ${seance.heureFin}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.checklist, size: 18),
                            label: const Text("Faire l'appel"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF000666),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
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
    );
  }
}