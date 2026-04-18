// lib/screens/enseignant/appel_screen.dart
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
  
  final Map<int, String> _absencesMap = {};
  final Map<int, String> _existingAbsences = {};
  bool _isSubmitting = false;
  bool _isLoadingExisting = true;
  int _presentCount = 0;
  int _absentCount = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Charger les étudiants et les absences existantes en parallèle
    final results = await Future.wait([
      ApiService.getEtudiantsByClasse(widget.seance.classeId),
      ApiService.getAbsencesBySeance(widget.seance.id),
    ]);
    
    if (mounted) {
      setState(() {
        _etudiantsFuture = Future.value(results[0] as List<Etudiant>);
        
        // Initialiser avec les absences existantes
        final existingAbsences = results[1] as List<Absence>;
        for (var absence in existingAbsences) {
          _existingAbsences[absence.etudiantId] = absence.statut;
          _absencesMap[absence.etudiantId] = absence.statut;
        }
        
        _updateCounts();
        _isLoadingExisting = false;
      });
    }
  }

  void _updateCounts() {
    _presentCount = _absencesMap.values.where((s) => s == 'present').length;
    _absentCount = _absencesMap.values.where((s) => s == 'absent').length;
  }

  List<Etudiant> _filterEtudiants(List<Etudiant> etudiants) {
    if (_searchQuery.isEmpty) return etudiants;
    
    final query = _searchQuery.toLowerCase();
    return etudiants.where((e) {
      return e.nom.toLowerCase().contains(query) || 
             e.prenom.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _soumettreAppel() async {
    setState(() => _isSubmitting = true);

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
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Appel enregistré avec succès !',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_presentCount présents • $_absentCount absents',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Erreur lors de l\'enregistrement'),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _marquerTousPresent() {
    setState(() {
      for (var etudiant in (_etudiantsFuture as dynamic).value) {
        _absencesMap[etudiant.id] = 'present';
      }
      _updateCounts();
    });
  }

  void _marquerTousAbsent() {
    setState(() {
      for (var etudiant in (_etudiantsFuture as dynamic).value) {
        _absencesMap[etudiant.id] = 'absent';
      }
      _updateCounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Faire l\'appel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF000666),
              ),
            ),
            Text(
              widget.seance.classeNom ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF000666),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000666)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist, color: Color(0xFF000666)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: const Text('Marquer tous présents'),
                        onTap: () {
                          _marquerTousPresent();
                          Navigator.pop(context);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.cancel, color: Colors.red),
                        title: const Text('Marquer tous absents'),
                        onTap: () {
                          _marquerTousAbsent();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            tooltip: 'Actions rapides',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec infos séance
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF000666), Color(0xFF1A237E)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.book, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.seance.matiereNom ?? 'Matière',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                widget.seance.dateSeance,
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.access_time, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '${widget.seance.heureDebut} - ${widget.seance.heureFin}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Compteurs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCounter('Présents', _presentCount, Colors.green),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildCounter('Absents', _absentCount, Colors.red),
                  ],
                ),
              ],
            ),
          ),

          // Barre de recherche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un étudiant...',
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

          const SizedBox(height: 16),

          // Liste des étudiants
          Expanded(
            child: _isLoadingExisting
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Etudiant>>(
                    future: _etudiantsFuture,
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
                                onPressed: _loadData,
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
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'Aucun étudiant dans cette classe',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      final etudiants = snapshot.data!;
                      final filteredEtudiants = _filterEtudiants(etudiants);

                      // Initialiser les étudiants non définis à 'present'
                      for (var etudiant in etudiants) {
                        _absencesMap.putIfAbsent(etudiant.id, () => 'present');
                      }

                      if (filteredEtudiants.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun résultat pour "$_searchQuery"',
                                style: const TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredEtudiants.length,
                        itemBuilder: (context, index) {
                          final etudiant = filteredEtudiants[index];
                          final statutActuel = _absencesMap[etudiant.id]!;
                          final hasExistingAbsence = _existingAbsences.containsKey(etudiant.id);
                          final isPresent = statutActuel == 'present';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: hasExistingAbsence
                                  ? Border.all(
                                      color: isPresent ? Colors.green : Colors.red,
                                      width: 1.5,
                                    )
                                  : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade100,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  // Avatar
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: isPresent
                                        ? Colors.green.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    child: Text(
                                      '${etudiant.prenom[0]}${etudiant.nom[0]}',
                                      style: TextStyle(
                                        color: isPresent ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Infos étudiant
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${etudiant.prenom} ${etudiant.nom}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (hasExistingAbsence)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isPresent
                                                  ? Colors.green.withOpacity(0.1)
                                                  : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'Déjà enregistré',
                                              style: TextStyle(
                                                color: isPresent ? Colors.green : Colors.red,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Switch pour présence/absence
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _absencesMap[etudiant.id] = 'present';
                                            _updateCounts();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isPresent
                                                ? Colors.green
                                                : Colors.grey.shade100,
                                            borderRadius: const BorderRadius.horizontal(
                                              left: Radius.circular(20),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.check,
                                                size: 16,
                                                color: isPresent ? Colors.white : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Présent',
                                                style: TextStyle(
                                                  color: isPresent ? Colors.white : Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _absencesMap[etudiant.id] = 'absent';
                                            _updateCounts();
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: !isPresent
                                                ? Colors.red
                                                : Colors.grey.shade100,
                                            borderRadius: const BorderRadius.horizontal(
                                              right: Radius.circular(20),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.close,
                                                size: 16,
                                                color: !isPresent ? Colors.white : Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Absent',
                                                style: TextStyle(
                                                  color: !isPresent ? Colors.white : Colors.grey,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
        ],
      ),
      
      // Bouton de validation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 55,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _soumettreAppel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000666),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        Text(
                          'Valider l\'appel ($_presentCount présents • $_absentCount absents)',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}