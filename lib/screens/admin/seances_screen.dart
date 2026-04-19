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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      final response = await ApiService.ajouterMatiere(result);
      Navigator.pop(context);
      
      if (response['success'] == 1) {
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
        builder: (context, setStateDialog) {
          // ✅ Détecter la taille d'écran
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;
          
          return AlertDialog(
            title: const Text('Ajouter une séance'),
            content: SizedBox(
              width: isMobile ? screenWidth * 0.9 : 450,
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
                          child: Text(e['nom'] ?? '', overflow: TextOverflow.ellipsis),
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
                          child: Text(c['nom'] ?? '', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) => setStateDialog(() => selectedClasse = value),
                    ),
                    const SizedBox(height: 16),
                    
                    // Matière avec bouton d'ajout rapide
                    // ✅ Matière avec bouton d'ajout rapide - corrigé pour mobile
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Matière',
                                        border: OutlineInputBorder(),
                                        // ✅ Réduire le padding interne
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      value: selectedMatiere,
                                      items: _matieres.map((m) {
                                        return DropdownMenuItem(
                                          value: m,
                                          child: Text(
                                            m['nom'] ?? '',
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (value) => setStateDialog(() => selectedMatiere = value),
                                    ),
                                  ),
                                  const SizedBox(width: 4), // ✅ Réduire l'espacement
                                  Container(
                                    width: 40, // ✅ Largeur fixe
                                    height: 40, // ✅ Hauteur fixe
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF000666).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.add, color: Color(0xFF000666), size: 20),
                                      padding: EdgeInsets.zero, // ✅ Supprimer le padding par défaut
                                      constraints: const BoxConstraints(), // ✅ Supprimer les contraintes
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
                      // ✅ Corriger les dates du showDatePicker
                          onTap: () async {
                            final now = DateTime.now();
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              // ✅ firstDate doit être avant ou égal à initialDate
                              firstDate: DateTime(2024, 1, 1),
                              // ✅ lastDate doit être après ou égal à initialDate
                              lastDate: DateTime(2030, 12, 31),
                            );
                            if (date != null) {
                              setStateDialog(() => selectedDate = date);
                            }
                          },
                    ),
                    const SizedBox(height: 8),
                    
                    // Heures - ✅ Responsive: Column sur mobile, Row sur desktop
                    if (isMobile)
                      Column(
                        children: [
                          _buildTimePicker(
                            context,
                            'Heure début',
                            selectedStartTime,
                            (time) => setStateDialog(() => selectedStartTime = time),
                          ),
                          const SizedBox(height: 8),
                          _buildTimePicker(
                            context,
                            'Heure fin',
                            selectedEndTime,
                            (time) => setStateDialog(() => selectedEndTime = time),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildTimePicker(
                              context,
                              'Heure début',
                              selectedStartTime,
                              (time) => setStateDialog(() => selectedStartTime = time),
                            ),
                          ),
                          Expanded(
                            child: _buildTimePicker(
                              context,
                              'Heure fin',
                              selectedEndTime,
                              (time) => setStateDialog(() => selectedEndTime = time),
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
          );
        },
      ),
    );
  }

  Widget _buildTimePicker(BuildContext context, String label, TimeOfDay time, Function(TimeOfDay) onTimeSelected) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(time.format(context)),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (selected != null) {
          onTimeSelected(selected);
        }
      },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
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
          // ✅ Barre de recherche responsive
          if (!isMobile)
            Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              child: _buildSearchField(),
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
      body: Column(
        children: [
          // ✅ Barre de recherche sur mobile
          if (isMobile)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchField(),
            ),
          Expanded(
            child: _isLoading
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
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _ajouterSeance,
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter une séance'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSeances.length,
                        itemBuilder: (context, index) {
                          final seance = _filteredSeances[index];
                          return _buildSeanceCard(seance, isMobile);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: 'Rechercher une séance...',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => setState(() => _searchQuery = ''),
              )
            : null,
      ),
    );
  }

  Widget _buildSeanceCard(dynamic seance, bool isMobile) {
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
        contentPadding: EdgeInsets.all(isMobile ? 12 : 16),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.class_, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Classe: ${seance['classe'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Enseignant: ${seance['enseignant'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_formatDate(seance['date_seance'] ?? '')} | ${seance['heure_debut'] ?? ''} - ${seance['heure_fin'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}