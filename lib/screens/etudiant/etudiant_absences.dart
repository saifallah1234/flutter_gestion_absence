// lib/screens/etudiant/etudiant_absences.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/pdf_service.dart';
import '../../models/etudiant.dart';

class EtudiantAbsencesScreen extends StatefulWidget {
  final Etudiant etudiant;

  const EtudiantAbsencesScreen({
    super.key,
    required this.etudiant,
  });

  @override
  State<EtudiantAbsencesScreen> createState() => _EtudiantAbsencesScreenState();
}

class _EtudiantAbsencesScreenState extends State<EtudiantAbsencesScreen> {
  List<Map<String, dynamic>> _seances = [];
  Map<String, dynamic> _statistics = {};
  List<Map<String, dynamic>> _subjectStats = [];
  List<Map<String, dynamic>> _warnings = [];
  List<Map<String, dynamic>> _criticalWarnings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.getEtudiantDashboard(widget.etudiant.id);
    
    if (response['success'] == 1 && mounted) {
      final data = response['data'];
      setState(() {
        _seances = (data['absences_list'] as List)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        _statistics = data['statistics'] ?? {};
        _subjectStats = List<Map<String, dynamic>>.from(_statistics['subject_stats'] ?? []);
        _warnings = List<Map<String, dynamic>>.from(data['warnings'] ?? []);
        _criticalWarnings = List<Map<String, dynamic>>.from(data['critical_warnings'] ?? []);
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = response['message'] ?? 'Erreur de chargement';
      });
    }

    setState(() => _isLoading = false);
  }

// ✅ Remplacer les getters existants
int getTotalAbsences() {
  final value = _statistics['absent'];
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int getTotalPresent() {
  final value = _statistics['present'];
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

int getTotalSeances() {
  final value = _statistics['total_seances'];
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double getAttendanceRate() {
  final value = _statistics['overall_attendance_rate'];
  if (value == null) return 100.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();  // ✅ Conversion int → double
  if (value is String) return double.tryParse(value) ?? 100.0;
  return 100.0;
}

double getAbsenceRate() {
  final value = _statistics['overall_absence_rate'];
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();  // ✅ Conversion int → double
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

  // Méthode pour exporter en PDF
  void _exportToPdf() {
    if (_seances.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune donnée à exporter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    PdfService.generateAbsencesPdf(
      nom: widget.etudiant.nom,
      prenom: widget.etudiant.prenom,
      seances: _seances,
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
          'Mes Absences',
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
        // ==========================================
        // BOUTON D'EXPORT PDF AJOUTÉ ICI
        // ==========================================
        actions: [
  Container(
    margin: const EdgeInsets.only(right: 8),
    child: IconButton(
      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF000666), size: 28),
      onPressed: _seances.isEmpty ? null : _exportToPdf,
      tooltip: 'Exporter en PDF',
    ),
  ),
],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAbsences,
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
                          onPressed: _loadAbsences,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatisticsCard(),
                        
                        const SizedBox(height: 20),
                        
                        if (_criticalWarnings.isNotEmpty || _warnings.isNotEmpty)
                          _buildWarningsSection(),
                        
                        if (_subjectStats.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSubjectStatistics(),
                        ],
                        
                        const SizedBox(height: 20),
                        
                        const Text(
                          'Historique des séances',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF000666),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (_seances.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('Aucune séance enregistrée'),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._seances.map((seance) => _buildSeanceCard(seance)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000666), Color(0xFF1A237E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${getTotalAbsences()}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const Text('ABSENCES', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${getTotalPresent()}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const Text('PRÉSENCES', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
              Container(width: 1, height: 50, color: Colors.white24),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${getTotalSeances()}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const Text('TOTAL', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildRateCard('Taux présence', getAttendanceRate(), Colors.greenAccent)),
              const SizedBox(width: 12),
              Expanded(child: _buildRateCard('Taux absence', getAbsenceRate(), 
                getAbsenceRate() > 20 ? Colors.redAccent : Colors.orangeAccent)),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildRateCard(String label, double value, Color color) {
  // ✅ S'assurer que value est un double valide
  final safeValue = value.clamp(0.0, 100.0);
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10)),
        Text('${safeValue.toInt()}%', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: safeValue / 100.0,  // ✅ Utiliser 100.0 pour garantir un double
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildWarningsSection() {
    final isCritical = _criticalWarnings.isNotEmpty;
    final warnings = isCritical ? _criticalWarnings : _warnings;
    
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCritical ? Colors.red.shade200 : Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCritical ? Icons.warning_amber : Icons.info_outline, 
                   color: isCritical ? Colors.red : Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text(
                isCritical ? 'Alertes critiques' : 'Avertissements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCritical ? Colors.red : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((warning) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.circle, size: 6, color: isCritical ? Colors.red.shade700 : Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    warning['message'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: isCritical ? Colors.red.shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSubjectStatistics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistiques par matière',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF000666),
          ),
        ),
        const SizedBox(height: 12),
        ..._subjectStats.map((subject) => _buildSubjectCard(subject)),
      ],
    );
  }
  // Dans _EtudiantAbsencesScreenState
int _parseInt(dynamic value, int defaultValue) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? defaultValue;
  if (value is double) return value.toInt();
  return defaultValue;
}

double _parseDouble(dynamic value, double defaultValue) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final absenceRate = _parseDouble(subject['absence_rate'], 0.0);
  final attendanceRate = _parseDouble(subject['attendance_rate'], 0.0);
  final present = _parseInt(subject['present'], 0);
  final totalSeances = _parseInt(subject['total_seances'], 0);
  final absent = _parseInt(subject['absent'], 0);
  
  final isDanger = absenceRate > 20;
  final isWarning = absenceRate > 10 && absenceRate <= 20;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDanger ? Colors.red.shade200 : (isWarning ? Colors.orange.shade200 : Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.book, size: 18, 
                        color: isDanger ? Colors.red : (isWarning ? Colors.orange : const Color(0xFF000666))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject['matiere'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDanger ? Colors.red.shade100 : (isWarning ? Colors.orange.shade100 : Colors.green.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${absenceRate.toStringAsFixed(1)}% absent',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDanger ? Colors.red.shade700 : (isWarning ? Colors.orange.shade700 : Colors.green.shade700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(width: 55, child: Text('Présence', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: attendanceRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      attendanceRate >= 80 ? Colors.green : (attendanceRate >= 60 ? Colors.orange : Colors.red),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${attendanceRate.toInt()}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: attendanceRate >= 80 ? Colors.green : (attendanceRate >= 60 ? Colors.orange : Colors.red)),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(width: 55, child: Text('Absence', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: absenceRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      absenceRate > 20 ? Colors.red : (absenceRate > 10 ? Colors.orange : Colors.green),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${absenceRate.toInt()}%',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: absenceRate > 20 ? Colors.red : (absenceRate > 10 ? Colors.orange : Colors.green)),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text('${subject['present']} / ${subject['total_seances']}', 
                       style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.cancel, size: 12, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text('${subject['absent']} absent', 
                       style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
          if (isDanger)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vous dépassez la limite de 20% d\'absences!',
                        style: TextStyle(fontSize: 11, color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeanceCard(Map<String, dynamic> seance) {
    String statut = seance['statut'] ?? 'absent';
    Color statusColor = statut == 'present'
        ? Colors.green
        : (statut == 'justifié' ? Colors.orange : Colors.red);
    String statusText = statut == 'present'
        ? 'Présent'
        : (statut == 'justifié' ? 'Justifié' : 'Absent');
    IconData statusIcon = statut == 'present'
        ? Icons.check_circle
        : (statut == 'justifié' ? Icons.assignment_late : Icons.cancel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade100, blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.book, color: Color(0xFF1A237E), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  seance['matiere'] ?? 'Matière',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(_formatDate(seance['date_seance'] ?? ''), 
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                    const SizedBox(width: 10),
                    Icon(Icons.access_time, size: 11, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(seance['heure_debut'] ?? '', 
                         style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 12),
                const SizedBox(width: 4),
                Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
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
}