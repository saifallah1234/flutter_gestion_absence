// lib/screens/admin/classes_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/classe.dart';

class ClassesScreen extends StatefulWidget {
  const ClassesScreen({super.key});

  @override
  State<ClassesScreen> createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  List<Classe> _classes = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAdminClasses();
    if (response['success'] == 1 && mounted) {
      final classesData = response['data'] as List;
      setState(() {
        _classes = classesData.map((c) => Classe.fromJson(c)).toList();
      });
    }
    setState(() => _isLoading = false);
  }

  List<Classe> get _filteredClasses {
    if (_searchQuery.isEmpty) return _classes;
    return _classes.where((c) {
      final nom = c.nom.toLowerCase();
      final niveau = (c.niveau ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) || niveau.contains(query);
    }).toList();
  }

  Future<void> _ajouterClasse() async {
    final result = await _showClasseForm();
    if (result != null && mounted) {
      final response = await ApiService.ajouterClasse(result);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Classe ajoutée avec succès')),
        );
        _loadClasses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de l\'ajout')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showClasseForm({Classe? classe}) async {
    final nomCtrl = TextEditingController(text: classe?.nom ?? '');
    final niveauCtrl = TextEditingController(text: classe?.niveau ?? '');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(classe == null ? 'Ajouter une classe' : 'Modifier une classe'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(labelText: 'Nom de la classe', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: niveauCtrl,
                decoration: const InputDecoration(labelText: 'Niveau (optionnel)', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (nomCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer le nom de la classe')),
                );
                return;
              }
              final data = {
                'nom': nomCtrl.text,
                'niveau': niveauCtrl.text.isNotEmpty ? niveauCtrl.text : null,
              };
              Navigator.pop(context, data);
            },
            child: Text(classe == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gestion des Classes',
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
            onPressed: _ajouterClasse,
            tooltip: 'Ajouter une classe',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredClasses.isEmpty
              ? const Center(child: Text('Aucune classe trouvée'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _filteredClasses.length,
                  itemBuilder: (context, index) {
                    final classe = _filteredClasses[index];
                    return Card(
                      elevation: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF000666),
                              const Color(0xFF1A237E).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.class_, color: Colors.white, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                classe.nom,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (classe.niveau != null && classe.niveau!.isNotEmpty)
                                Text(
                                  classe.niveau!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}