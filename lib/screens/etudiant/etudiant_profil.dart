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
  Map<String, dynamic> _stats = {};
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

    try {
      // Charger les données du profil et les statistiques en parallèle
      final results = await Future.wait([
        ApiService.getEtudiantProfil(widget.etudiant.id),
        ApiService.getEtudiantStats(widget.etudiant.id),
      ]);
      
      if (mounted) {
        final profilResponse = results[0];
        final statsResponse = results[1];
        
        if (profilResponse['success'] == 1) {
          setState(() {
            _profilData = profilResponse['data'] ?? {};
          });
        }
        
        if (statsResponse['success'] == 1) {
          setState(() {
            _stats = statsResponse['data'] ?? {};
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: $e';
        });
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Calculs dynamiques
  int get _totalSeances => _parseToInt(_stats['total_seances']);
  int get _totalPresent => _parseToInt(_stats['total_present']);
  int get _totalAbsent => _parseToInt(_stats['total_absent']);
  double get _attendanceRate => _parseToDouble(_stats['attendance_rate'], 100.0);
  double get _absenceRate => _parseToDouble(_stats['absence_rate'], 0.0);

  int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  double _parseToDouble(dynamic value, double defaultValue) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }

  String get _trend {
    if (_attendanceRate >= 80) return 'up';
    if (_attendanceRate >= 50) return 'stable';
    return 'down';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF000666)),
            onPressed: _loadProfil,
          ),
        ],
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
                        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
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
                        // Avatar et infos de base
                        _buildProfileHeader(),
                        const SizedBox(height: 24),
                        
                        // Cartes d'information
                        _buildInfoSection(),
                        const SizedBox(height: 24),
                        
                        // Statistiques globales
                        _buildGlobalStatsCard(),
                        const SizedBox(height: 20),
                        
                        // Graphique de présence
                        _buildAttendanceChart(),
                        const SizedBox(height: 20),
                        
                        // Statistiques par matière
                        if (_stats['by_matiere'] != null && (_stats['by_matiere'] as List).isNotEmpty)
                          _buildStatsByMatiere(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
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
              '${widget.etudiant.prenom.isNotEmpty ? widget.etudiant.prenom[0] : ''}${widget.etudiant.nom.isNotEmpty ? widget.etudiant.nom[0] : ''}',
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: _getStatusColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getStatusColor().withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(),
                size: 14,
                color: _getStatusColor(),
              ),
              const SizedBox(width: 6),
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _profilData['email'] ?? 'Non renseigné',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.class_outlined,
            label: 'Classe',
            value: _profilData['classe'] ?? 'Non assignée',
          ),
          const Divider(height: 24),
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'ID Étudiant',
            value: '#${widget.etudiant.id}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF000666).withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF000666), size: 20),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1B23),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalStatsCard() {
    return Container(
      width: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '$_totalSeances',
                'Séances',
                Icons.calendar_today,
              ),
              _buildStatItem(
                '$_totalPresent',
                'Présences',
                Icons.check_circle,
              ),
              _buildStatItem(
                '$_totalAbsent',
                'Absences',
                Icons.cancel,
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildRateCard(
                  'Taux de présence',
                  _attendanceRate,
                  Colors.greenAccent,
                  _trend,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRateCard(
                  'Taux d\'absence',
                  _absenceRate,
                  _absenceRate > 20 ? Colors.redAccent : Colors.orangeAccent,
                  _trend == 'up' ? 'down' : (_trend == 'down' ? 'up' : 'stable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRateCard(String label, double value, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 6),
              if (trend != 'stable')
                Icon(
                  trend == 'up' ? Icons.trending_up : Icons.trending_down,
                  size: 14,
                  color: trend == 'up' ? Colors.greenAccent : Colors.redAccent,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart() {
    final monthlyData = _stats['monthly_data'] as List? ?? [];
    
    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'Évolution de la présence',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000666),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: monthlyData.map((data) {
                final month = (data['month'] ?? '').toString();
                final rate = _parseToDouble(data['rate'], 0.0);
                
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 120 * (rate / 100.0),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              rate > 80 ? Colors.green : Colors.orange,
                              rate > 80 ? Colors.green.shade700 : Colors.orange.shade700,
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        month,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        '${rate.toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsByMatiere() {
    final matieres = _stats['by_matiere'] as List;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
            'Par matière',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000666),
            ),
          ),
          const SizedBox(height: 16),
          ...matieres.take(5).map((matiere) {
            final rate = _parseToDouble(matiere['attendance_rate'], 0.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          matiere['matiere'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${rate.toInt()}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: rate > 80 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (rate / 100.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          rate > 80 ? Colors.green : Colors.orange,
                        ),
                        minHeight: 6,
                      ),
                  ),  
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    if (_attendanceRate >= 80) return Colors.green;
    if (_attendanceRate >= 50) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (_attendanceRate >= 80) return Icons.check_circle;
    if (_attendanceRate >= 50) return Icons.warning;
    return Icons.error;
  }

  String _getStatusText() {
    if (_attendanceRate >= 80) return 'Bon taux de présence';
    if (_attendanceRate >= 50) return 'Présence moyenne';
    return 'Présence insuffisante';
  }
}