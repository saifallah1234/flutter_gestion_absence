import 'package:flutter/material.dart';
import '../../models/seance.dart';
import '../../models/etudiant.dart';
import '../../models/absence.dart';
import '../../services/api_service.dart';

class AppelScreen extends StatefulWidget {
  final Seance seance;

  const AppelScreen({super.key, required this.seance});

  @override
  State<AppelScreen> createState() => _AppelScreenState();
}

class _AppelScreenState extends State<AppelScreen> {
  late Future<List<Etudiant>> _etudiantsFuture;
  
  // Dictionnaire pour stocker le statut de chaque étudiant (id -> 'present' / 'absent')
  final Map<int, String> _absencesMap = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _etudiantsFuture = ApiService.getEtudiantsByClasse(widget.seance.classeId);
  }

  Future<void> _soumettreAppel() async {
    setState(() => _isSubmitting = true);

    // Convertir notre dictionnaire en liste d'objets Absence
    List<Absence> listeAppel = _absencesMap.entries.map((entry) {
      return Absence(
        seanceId: widget.seance.id,
        etudiantId: entry.key,
        statut: entry.value,
      );
    }).toList();

    bool success = await ApiService.soumettreAppel(widget.seance.id, listeAppel);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appel enregistré avec succès !'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Retour à la liste des séances
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'enregistrement.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appel : ${widget.seance.classeNom}'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFE8E7F2),
            width: double.infinity,
            child: Text(
              '${widget.seance.matiereNom} • ${widget.seance.dateSeance}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Etudiant>>(
              future: _etudiantsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Aucun étudiant trouvé pour cette classe.'));
                }

                final etudiants = snapshot.data!;

                // Initialiser tous les étudiants à 'present' par défaut si pas encore fait
                for (var etudiant in etudiants) {
                  _absencesMap.putIfAbsent(etudiant.id, () => 'present');
                }

                return ListView.builder(
                  itemCount: etudiants.length,
                  itemBuilder: (context, index) {
                    final etudiant = etudiants[index];
                    final statutActuel = _absencesMap[etudiant.id]!;

                    return ListTile(
                      title: Text('${etudiant.nom} ${etudiant.prenom}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'present', label: Text('Présent'), icon: Icon(Icons.check)),
                          ButtonSegment(value: 'absent', label: Text('Absent'), icon: Icon(Icons.close)),
                        ],
                        selected: {statutActuel},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _absencesMap[etudiant.id] = newSelection.first;
                          });
                        },
                        style: SegmentedButton.styleFrom(
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor: statutActuel == 'present' ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _soumettreAppel,
            child: _isSubmitting 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Valider l\'appel', style: TextStyle(fontSize: 18)),
          ),
        ),
      ),
    );
  }
}