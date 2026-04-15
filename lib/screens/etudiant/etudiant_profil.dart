// lib/screens/etudiant/etudiant_profil.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/etudiant.dart';

class EtudiantProfilScreen extends StatefulWidget {
  final Etudiant etudiant;

  const EtudiantProfilScreen({
    super.key,
    required this.etudiant,
  });

  @override
  State<EtudiantProfilScreen> createState() => _EtudiantProfilScreenState();
}

class _EtudiantProfilScreenState extends State<EtudiantProfilScreen> {
  Map<String, dynamic> _profilData = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getEtudiantProfil(widget.etudiant.id);
    
    if (response['success'] == 1 && mounted) {
      setState(() {
        _profilData = response['data'] ?? {};
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = response['message'] ?? 'Erreur de chargement';
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: Color(0xFF000666),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF000666)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfil,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadProfil,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF000666), Color(0xFF1A237E)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF000666).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '${widget.etudiant.prenom[0]}${widget.etudiant.nom[0]}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${widget.etudiant.prenom} ${widget.etudiant.nom}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF000666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF000666).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _profilData['classe'] ?? 'Étudiant',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF000666),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        
                        // Information Cards
                        _buildInfoCard(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _profilData['email'] ?? 'Non renseigné',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.class_outlined,
                          label: 'Classe',
                          value: _profilData['classe'] ?? 'Non assignée',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoCard(
                          icon: Icons.badge_outlined,
                          label: 'ID Étudiant',
                          value: '#${widget.etudiant.id}',
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Stats Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Statistiques',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF000666),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Total séances',
                                      _profilData['total_seances']?.toString() ?? '0',
                                      Icons.calendar_today,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Présences',
                                      _profilData['total_present']?.toString() ?? '0',
                                      Icons.check_circle,
                                      Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Absences',
                                      _profilData['total_absent']?.toString() ?? '0',
                                      Icons.cancel,
                                      Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildStatItem(
                                      'Taux présence',
                                      '${(_profilData['attendance_rate'] ?? 100).toInt()}%',
                                      Icons.trending_up,
                                      Colors.green,
                                    ),
                                  ),
                                  Expanded(
                                    child: _buildStatItem(
                                      'Taux absence',
                                      '${(_profilData['absence_rate'] ?? 0).toInt()}%',
                                      Icons.trending_down,
                                      Colors.red,
                                    ),
                                  ),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF000666).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF000666), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1B23),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color ?? const Color(0xFF000666)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF000666),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}