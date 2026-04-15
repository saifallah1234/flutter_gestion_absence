// lib/screens/admin/seances_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SeancesScreen extends StatefulWidget {
  const SeancesScreen({super.key});

  @override
  State<SeancesScreen> createState() => _SeancesScreenState();
}

class _SeancesScreenState extends State<SeancesScreen> {
  List<dynamic> _seances = [];
  List<dynamic> _enseignants = [];
  List<dynamic> _classes = [];
  List<dynamic> _matieres = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadSeances(),
      _loadFormData(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadSeances() async {
    final response = await ApiService.getAdminSeances();
    if (response['success'] == 1 && mounted) {
      setState(() => _seances = response['data'] ?? []);
    }
  }

  Future<void> _loadFormData() async {
    final response = await ApiService.getSeanceFormData();
    if (response['success'] == 1 && mounted) {
      final data = response['data'];
      setState(() {
        _enseignants = data['enseignants'] ?? [];
        _classes = data['classes'] ?? [];
        _matieres = data['matieres'] ?? [];
      });
    }
  }

  List<dynamic> get _filteredSeances {
    if (_searchQuery.isEmpty) return _seances;
    return _seances.where((s) {
      final matiere = (s['matiere'] ?? '').toLowerCase();
      final classe = (s['classe'] ?? '').toLowerCase();
      final enseignant = (s['enseignant'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return matiere.contains(query) || classe.contains(query) || enseignant.contains(query);
    }).toList();
  }

  Future<void> _ajouterSeance() async {
    final result = await _showSeanceForm();
    if (result != null && mounted) {
      final response = await ApiService.ajouterSeance(result);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Séance ajoutée avec succès')),
        );
        _loadSeances();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de l\'ajout')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showSeanceForm() async {
    dynamic selectedEnseignant;
    dynamic selectedClasse;
    dynamic selectedMatiere;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedStartTime = TimeOfDay.now();
    TimeOfDay selectedEndTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Ajouter une séance'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: 'Enseignant', border: OutlineInputBorder()),
                    value: selectedEnseignant,
                    items: _enseignants.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e['nom']),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedEnseignant = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: 'Classe', border: OutlineInputBorder()),
                    value: selectedClasse,
                    items: _classes.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c['nom']),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedClasse = value),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(labelText: 'Matière', border: OutlineInputBorder()),
                    value: selectedMatiere,
                    items: _matieres.map((m) {
                      return DropdownMenuItem(
                        value: m,
                        child: Text(m['nom']),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedMatiere = value),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Date'),
                    subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2024),
                        lastDate: DateTime(2026),
                      );
                      if (date != null) {
                        setStateDialog(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          title: const Text('Heure début'),
                          subtitle: Text(selectedStartTime.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedStartTime,
                            );
                            if (time != null) {
                              setStateDialog(() => selectedStartTime = time);
                            }
                          },
                        ),
                      ),
                      Expanded(
                        child: ListTile(
                          title: const Text('Heure fin'),
                          subtitle: Text(selectedEndTime.format(context)),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedEndTime,
                            );
                            if (time != null) {
                              setStateDialog(() => selectedEndTime = time);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (selectedEnseignant == null || selectedClasse == null || selectedMatiere == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs')),
                  );
                  return;
                }
                final data = {
                  'enseignant_id': selectedEnseignant['id'],
                  'classe_id': selectedClasse['id'],
                  'matiere_id': selectedMatiere['id'],
                  'date_seance': '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  'heure_debut': '${selectedStartTime.hour.toString().padLeft(2, '0')}:${selectedStartTime.minute.toString().padLeft(2, '0')}:00',
                  'heure_fin': '${selectedEndTime.hour.toString().padLeft(2, '0')}:${selectedEndTime.minute.toString().padLeft(2, '0')}:00',
                };
                Navigator.pop(context, data);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return date;
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gestion des Séances',
          style: TextStyle(color: Color(0xFF000666), fontWeight: FontWeight.w700),
        ),
        actions: [
          Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF000666)),
            onPressed: _ajouterSeance,
            tooltip: 'Ajouter une séance',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSeances.isEmpty
              ? const Center(child: Text('Aucune séance trouvée'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredSeances.length,
                  itemBuilder: (context, index) {
                    final seance = _filteredSeances[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF000666).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.schedule, color: Color(0xFF000666)),
                        ),
                        title: Text(
                          seance['matiere'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Classe: ${seance['classe'] ?? ''}'),
                            Text('Enseignant: ${seance['enseignant'] ?? ''}'),
                            Text('Date: ${_formatDate(seance['date_seance'] ?? '')} | Heure: ${seance['heure_debut'] ?? ''} - ${seance['heure_fin'] ?? ''}'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}