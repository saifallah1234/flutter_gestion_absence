// lib/screens/admin/enseignants_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class EnseignantsScreen extends StatefulWidget {
  const EnseignantsScreen({super.key});

  @override
  State<EnseignantsScreen> createState() => _EnseignantsScreenState();
}

class _EnseignantsScreenState extends State<EnseignantsScreen> {
  List<dynamic> _enseignants = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEnseignants();
  }

  Future<void> _loadEnseignants() async {
    setState(() => _isLoading = true);
    final response = await ApiService.getAdminEnseignants();
    if (response['success'] == 1 && mounted) {
      setState(() => _enseignants = response['data'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredEnseignants {
    if (_searchQuery.isEmpty) return _enseignants;
    return _enseignants.where((e) {
      final nom = (e['nom'] ?? '').toLowerCase();
      final prenom = (e['prenom'] ?? '').toLowerCase();
      final email = (e['email'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return nom.contains(query) || prenom.contains(query) || email.contains(query);
    }).toList();
  }

  Future<void> _ajouterEnseignant() async {
    final result = await _showEnseignantForm();
    if (result != null && mounted) {
      final response = await ApiService.ajouterEnseignant(result);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enseignant ajouté avec succès')),
        );
        _loadEnseignants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de l\'ajout')),
        );
      }
    }
  }

  Future<void> _modifierEnseignant(dynamic enseignant) async {
    final result = await _showEnseignantForm(enseignant: enseignant);
    if (result != null && mounted) {
      final response = await ApiService.modifierEnseignant(enseignant['id'], result);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enseignant modifié avec succès')),
        );
        _loadEnseignants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de la modification')),
        );
      }
    }
  }

  Future<void> _supprimerEnseignant(dynamic enseignant) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Text('Supprimer ${enseignant['prenom']} ${enseignant['nom']} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      final response = await ApiService.supprimerEnseignant(enseignant['id']);
      if (response['success'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enseignant supprimé avec succès')),
        );
        _loadEnseignants();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Erreur lors de la suppression')),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showEnseignantForm({dynamic enseignant}) async {
    final nomCtrl = TextEditingController(text: enseignant?['nom'] ?? '');
    final prenomCtrl = TextEditingController(text: enseignant?['prenom'] ?? '');
    final emailCtrl = TextEditingController(text: enseignant?['email'] ?? '');
    final specialiteCtrl = TextEditingController(text: enseignant?['specialite'] ?? '');
    final passwordCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enseignant == null ? 'Ajouter un enseignant' : 'Modifier un enseignant'),
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
                const SizedBox(height: 16),
                TextField(
                  controller: specialiteCtrl,
                  decoration: const InputDecoration(labelText: 'Spécialité', border: OutlineInputBorder()),
                ),
                if (enseignant == null) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
                  ),
                ],
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
                  const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                );
                return;
              }
              if (enseignant == null && passwordCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer un mot de passe')),
                );
                return;
              }
              final data = {
                'nom': nomCtrl.text,
                'prenom': prenomCtrl.text,
                'email': emailCtrl.text,
                'specialite': specialiteCtrl.text,
              };
              if (enseignant == null) {
                data['password'] = passwordCtrl.text;
              }
              Navigator.pop(context, data);
            },
            child: Text(enseignant == null ? 'Ajouter' : 'Modifier'),
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
          'Gestion des Enseignants',
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
            onPressed: _ajouterEnseignant,
            tooltip: 'Ajouter un enseignant',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredEnseignants.isEmpty
              ? const Center(child: Text('Aucun enseignant trouvé'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredEnseignants.length,
                  itemBuilder: (context, index) {
                    final enseignant = _filteredEnseignants[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF000666).withOpacity(0.1),
                          child: Text(
                            '${enseignant['prenom']?[0]}${enseignant['nom']?[0]}',
                            style: const TextStyle(color: Color(0xFF000666), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text('${enseignant['prenom']} ${enseignant['nom']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(enseignant['email'] ?? ''),
                            if (enseignant['specialite'] != null && enseignant['specialite'].isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  enseignant['specialite'],
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
                              onPressed: () => _modifierEnseignant(enseignant),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _supprimerEnseignant(enseignant),
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