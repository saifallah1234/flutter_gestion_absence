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

  // ✅ Getter pour filtrer les séances
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

  // ✅ Type de retour corrigé : Future<dynamic?> au lieu de Future<void>
  Future<dynamic?> _ajouterMatiereRapide() async {
    final nomCtrl = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle matière'),
        content: TextField(
          controller: nomCtrl,
          decoration: const InputDecoration(
            labelText: 'Nom de la matière',
            border: OutlineInputBorder(),
            hintText: 'Ex: Mathématiques, Physique...',
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(context, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final nom = nomCtrl.text.trim();
              if (nom.isNotEmpty) {
                Navigator.pop(context, nom);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && mounted) {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final response = await ApiService.ajouterMatiere(result);
      
      // Fermer le dialogue de chargement
      Navigator.pop(context);
      
      if (response['success'] == 1) {
        // Ajouter la nouvelle matière à la liste
        final nouvelleMatiere = response['data'];
        setState(() {
          _matieres.add(nouvelleMatiere);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Matière "$result" ajoutée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        // ✅ Retourner la nouvelle matière
        return nouvelleMatiere;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Erreur lors de l\'ajout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    return null;
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
                  // Enseignant
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                      labelText: 'Enseignant',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedEnseignant,
                    items: _enseignants.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(e['nom'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedEnseignant = value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Classe
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                      labelText: 'Classe',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedClasse,
                    items: _classes.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c['nom'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) => setStateDialog(() => selectedClasse = value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Matière avec bouton d'ajout rapide
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField(
                          decoration: const InputDecoration(
                            labelText: 'Matière',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedMatiere,
                          items: _matieres.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(m['nom'] ?? ''),
                            );
                          }).toList(),
                          onChanged: (value) => setStateDialog(() => selectedMatiere = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF000666).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add, color: Color(0xFF000666)),
                          onPressed: () async {
                            final nouvelleMatiere = await _ajouterMatiereRapide();
                            if (nouvelleMatiere != null) {
                              setStateDialog(() {
                                selectedMatiere = nouvelleMatiere;
                              });
                            }
                          },
                          tooltip: 'Ajouter une matière',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text('${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'),
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
                  
                  // Heures
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
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
                          contentPadding: EdgeInsets.zero,
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
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
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF000666)),
            onPressed: _loadData,
            tooltip: 'Actualiser',
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty ? Icons.schedule : Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'Aucune séance' : 'Aucun résultat pour "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredSeances.length,
                  itemBuilder: (context, index) {
                    final seance = _filteredSeances[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
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
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.class_, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('Classe: ${seance['classe'] ?? ''}'),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('Enseignant: ${seance['enseignant'] ?? ''}'),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                                const SizedBox(width: 4),
                                Text('${_formatDate(seance['date_seance'] ?? '')} | ${seance['heure_debut'] ?? ''} - ${seance['heure_fin'] ?? ''}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}