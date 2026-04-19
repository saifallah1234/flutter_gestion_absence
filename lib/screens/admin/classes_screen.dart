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

  Future<Map<String, dynamic>?> _showClasseForm() async {
    final nomCtrl = TextEditingController();
    final niveauCtrl = TextEditingController();

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une classe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de la classe',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: niveauCtrl,
                decoration: const InputDecoration(
                  labelText: 'Niveau (optionnel)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: L1, L2, L3, M1, M2',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nomCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez entrer le nom de la classe')),
                );
                return;
              }
              final data = {
                'nom': nomCtrl.text.trim(),
                'niveau': niveauCtrl.text.trim().isNotEmpty ? niveauCtrl.text.trim() : null,
              };
              Navigator.pop(context, data);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Responsive : nombre de colonnes selon la largeur d'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth < 600 ? 1 : (screenWidth < 900 ? 2 : 3);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gestion des Classes',
          style: TextStyle(
            color: Color(0xFF000666),
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // ✅ Barre de recherche visible seulement sur écrans larges
          if (screenWidth > 600)
            Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              child: _buildSearchField(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF000666)),
            onPressed: _loadClasses,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF000666)),
            onPressed: _ajouterClasse,
            tooltip: 'Ajouter une classe',
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Barre de recherche sur mobile (sous l'AppBar)
          if (screenWidth <= 600)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchField(),
            ),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClasses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isEmpty ? Icons.class_ : Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty 
                                  ? 'Aucune classe disponible' 
                                  : 'Aucune classe ne correspond à "$_searchQuery"',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _ajouterClasse,
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter une classe'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          // ✅ Aspect ratio adapté selon le nombre de colonnes
                          childAspectRatio: crossAxisCount == 1 ? 5.0 : 1.5,
                        ),
                        itemCount: _filteredClasses.length,
                        itemBuilder: (context, index) {
                          final classe = _filteredClasses[index];
                          return _buildClasseCard(classe, crossAxisCount);
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
        hintText: 'Rechercher une classe...',
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

Widget _buildClasseCard(Classe classe, int crossAxisCount) {
  // ✅ Layout horizontal pour mobile (1 colonne)
  if (crossAxisCount == 1) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000666), Color(0xFF1A237E)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.class_, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            // ✅ Utiliser Expanded avec un Row/Column flexible
            Expanded(
              child: Wrap(  // ✅ Wrap au lieu de Column pour éviter l'overflow
                direction: Axis.vertical,
                spacing: 4,
                children: [
                  Text(
                    classe.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (classe.niveau != null && classe.niveau!.isNotEmpty)
                    Text(
                      classe.niveau!,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // ✅ Layout grille pour tablette/desktop (2+ colonnes)
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.class_, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          Flexible(
            child: Text(
              classe.nom,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (classe.niveau != null && classe.niveau!.isNotEmpty)
            Flexible(
              child: Text(
                classe.niveau!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    ),
  );
}
}