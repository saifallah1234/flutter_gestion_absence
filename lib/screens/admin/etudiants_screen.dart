// lib/screens/admin/etudiants_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/classe.dart';

class EtudiantsScreen extends StatefulWidget {
  const EtudiantsScreen({super.key});

  @override
  State<EtudiantsScreen> createState() => _EtudiantsScreenState();
}

class _EtudiantsScreenState extends State<EtudiantsScreen> {
  List<dynamic> _etudiants = [];
  List<Classe> _classes = [];
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
      _loadEtudiants(),
      _loadClasses(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadEtudiants() async {
    final response = await ApiService.getAdminEtudiants();
    if (response['success'] == 1 && mounted) {
      setState(() => _etudiants = response['data'] ?? []);
    }
  }

  Future<void> _loadClasses() async {
    final response = await ApiService.getAdminClasses();
    if (response['success'] == 1 && mounted) {
      final classesData = response['data'] as List;
      setState(() {
        _classes = classesData.map((c) => Classe.fromJson(c)).toList();
      });
    }
  }

  List<dynamic> get _filteredEtudiants {
    if (_searchQuery.isEmpty) return _etudiants;
    return _etudiants.where((e) {
      final nom = (e['nom'] ?? '').toLowerCase();
      final prenom = (e['prenom'] ?? '').toLowerCase();
      final email = (e['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) || prenom.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _ajouterEtudiant() async {
    final result = await _showEtudiantForm();
    if (result != null && mounted) {
      final response = await ApiService.ajouterEtudiant(result);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant ajouté avec succès')),
        );
        _loadEtudiants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de l\'ajout')),
        );
      }
    }
  }

  Future<void> _modifierEtudiant(dynamic etudiant) async {
    final result = await _showEtudiantForm(etudiant: etudiant);
    if (result != null && mounted) {
      final response = await ApiService.modifierEtudiant(etudiant['id'], result);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant modifié avec succès')),
        );
        _loadEtudiants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de la modification')),
        );
      }
    }
  }

  Future<void> _supprimerEtudiant(dynamic etudiant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer ${etudiant['prenom']} ${etudiant['nom']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final response = await ApiService.supprimerEtudiant(etudiant['id']);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Étudiant supprimé avec succès')),
        );
        _loadEtudiants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de la suppression')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showEtudiantForm({dynamic etudiant}) async {
    final nomCtrl = TextEditingController(text: etudiant?['nom'] ?? '');
    final prenomCtrl = TextEditingController(text: etudiant?['prenom'] ?? '');
    final emailCtrl = TextEditingController(text: etudiant?['email'] ?? '');
    final passwordCtrl = TextEditingController();
    Classe? selectedClasse;
    
    if (etudiant != null && _classes.isNotEmpty) {
      selectedClasse = _classes.firstWhere(
        (c) => c.nom == etudiant['classe'],
        orElse: () => _classes.first,
      );
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(etudiant == null ? 'Ajouter un étudiant' : 'Modifier un étudiant'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nomCtrl,
                    decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: prenomCtrl,
                    decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  if (etudiant == null) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Classe>(
                    value: selectedClasse,
                    decoration: const InputDecoration(labelText: 'Classe', border: OutlineInputBorder()),
                    items: _classes.map((classe) {
                      return DropdownMenuItem(
                        value: classe,
                        child: Text('${classe.nom} ${classe.niveau ?? ''}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() => selectedClasse = value);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (nomCtrl.text.isEmpty || prenomCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs')),
                  );
                  return;
                }
                if (etudiant == null && passwordCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez entrer un mot de passe')),
                  );
                  return;
                }
                final data = {
                  'nom': nomCtrl.text,
                  'prenom': prenomCtrl.text,
                  'email': emailCtrl.text,
                  'classe_id': selectedClasse?.id,
                };
                if (etudiant == null) {
                  data['password'] = passwordCtrl.text;
                }
                Navigator.pop(context, data);
              },
              child: Text(etudiant == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        ),
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
          'Gestion des Étudiants',
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
            onPressed: _ajouterEtudiant,
            tooltip: 'Ajouter un étudiant',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredEtudiants.isEmpty
              ? const Center(child: Text('Aucun étudiant trouvé'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredEtudiants.length,
                  itemBuilder: (context, index) {
                    final etudiant = _filteredEtudiants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF000666).withOpacity(0.1),
                          child: Text(
                            '${etudiant['prenom']?[0]}${etudiant['nom']?[0]}',
                            style: const TextStyle(color: Color(0xFF000666), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${etudiant['prenom']} ${etudiant['nom']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(etudiant['email'] ?? ''),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF000666).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                etudiant['classe'] ?? 'Sans classe',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _modifierEtudiant(etudiant),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _supprimerEtudiant(etudiant),
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