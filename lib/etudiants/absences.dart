import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'profileetudiant.dart';
import '/services/pdf_service.dart';
class Absence {
  final String statut;
  final String dateSeance;
  final String heureDebut;
  final String matiere;

  Absence({
    required this.statut,
    required this.dateSeance,
    required this.heureDebut,
    required this.matiere,
  });

  factory Absence.fromJson(Map<String, dynamic> json) {
    return Absence(
      statut: json['statut'] ?? '',
      dateSeance: json['date_seance'] ?? '',
      heureDebut: json['heure_debut'] ?? '',
      matiere: json['matiere'] ?? '',
    );
  }
}

class AbsencesPage extends StatefulWidget {
  final int etudiantId;
  final String nom;
  final String prenom;

  const AbsencesPage({
    super.key,
    required this.etudiantId,
    required this.nom,
    required this.prenom,
  });

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  List<Absence> _absences = [];
  Map<String, dynamic> _statistics = {};
  List<dynamic> _warnings = [];
  List<dynamic> _criticalWarnings = [];
  Map<String, dynamic> _student = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _fetchAbsences();
  }

  Future<void> _fetchAbsences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost/gest_absence_api/etudiant/absences.php?id=${widget.etudiantId}');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == 1) {
          final dashboardData = data['data'];
          
          setState(() {
            _absences = (dashboardData['absences_list'] as List)
                .map((item) => Absence.fromJson(item))
                .toList();
            
            _statistics = dashboardData['statistics'] ?? {};
            _warnings = dashboardData['warnings'] ?? [];
            _criticalWarnings = dashboardData['critical_warnings'] ?? [];
            _student = dashboardData['student'] ?? {};
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'No data found';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load absences';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int getTotalAbsences() {
    return _statistics['absent'] ?? 0;
  }

  int getTotalPresent() {
    return _statistics['present'] ?? 0;
  }

  int getTotalSeances() {
    return _statistics['total_seances'] ?? 0;
  }

  int getJustifiedAbsences() {
    return _absences.where((a) => a.statut == 'justifié').length;
  }

  double getAttendanceRate() {
    return _statistics['overall_attendance_rate'] ?? 100.0;
  }

  double getAbsenceRate() {
    return _statistics['overall_absence_rate'] ?? 0.0;
  }

  List<dynamic> get _subjectStats => _statistics['subject_stats'] ?? [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 0) {
      _fetchAbsences();
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileEtudiantPage(
            etudiantId: widget.etudiantId,
            nom: widget.nom,
            prenom: widget.prenom,
          ),
        ),
      );
    }
  }

  Widget _buildSubjectStatistics() {
    if (_subjectStats.isEmpty) {
      return const SizedBox();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Statistiques par matière',
          style: TextStyle(
            color: Color(0xFF000666),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ..._subjectStats.map((subject) => _buildSubjectCard(subject)).toList(),
      ],
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    final absenceRate = subject['absence_rate'];
    final attendanceRate = subject['attendance_rate'];
    final isDanger = absenceRate > 20;
    final isWarning = absenceRate > 10 && absenceRate <= 20;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDanger 
              ? Colors.red.shade200 
              : (isWarning ? Colors.orange.shade200 : Colors.grey.shade200),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                    Icon(
                      Icons.book,
                      size: 20,
                      color: isDanger ? Colors.red : (isWarning ? Colors.orange : const Color(0xFF000666)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subject['matiere'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1B23),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDanger 
                      ? Colors.red.shade100 
                      : (isWarning ? Colors.orange.shade100 : Colors.green.shade100),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${absenceRate.toStringAsFixed(1)}% absent',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDanger 
                        ? Colors.red.shade700
                        : (isWarning ? Colors.orange.shade700 : Colors.green.shade700),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Horizontal bar chart for attendance rate
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Présence',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: attendanceRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      attendanceRate >= 80 
                          ? Colors.green 
                          : (attendanceRate >= 60 ? Colors.orange : Colors.red),
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 45,
                child: Text(
                  '${attendanceRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: attendanceRate >= 80 
                        ? Colors.green 
                        : (attendanceRate >= 60 ? Colors.orange : Colors.red),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Horizontal bar chart for absence rate
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  'Absence',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: absenceRate / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      absenceRate > 20 ? Colors.red : (absenceRate > 10 ? Colors.orange : Colors.green),
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 45,
                child: Text(
                  '${absenceRate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: absenceRate > 20 
                        ? Colors.red 
                        : (absenceRate > 10 ? Colors.orange : Colors.green),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${subject['present']} / ${subject['total_seances']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.cancel, size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 4),
                  Text(
                    '${subject['absent']} absent',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          
          if (isDanger)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Vous dépassez la limite de 20% d\'absences!',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade700),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 80, left: 24, right: 24, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mes Absences',
                        style: TextStyle(
                          color: Color(0xFF000666),
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Consultez votre historique de présence académique.',
                        style: TextStyle(
                          color: Color(0xFF454652),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Statistics Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF000666), Color(0xFF1A237E)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x19000000), blurRadius: 6, offset: Offset(0, 4)),
                        BoxShadow(color: Color(0x19000000), blurRadius: 15, offset: Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart, color: Colors.white.withOpacity(0.8), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'STATISTIQUES GÉNÉRALES',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${getTotalAbsences()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'ABSENCES',
                                    style: TextStyle(
                                      color: Color(0xCCE0E0FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${getTotalPresent()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'PRÉSENCES',
                                    style: TextStyle(
                                      color: Color(0xCCE0E0FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${getTotalSeances()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Text(
                                    'TOTAL',
                                    style: TextStyle(
                                      color: Color(0xCCE0E0FF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Taux présence',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                                    ),
                                    Text(
                                      '${getAttendanceRate().toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: getAttendanceRate() / 100,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Taux absence',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                                    ),
                                    Text(
                                      '${getAbsenceRate().toInt()}%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: getAbsenceRate() / 100,
                                        backgroundColor: Colors.white.withOpacity(0.3),
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        minHeight: 4,
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
                  
                  const SizedBox(height: 24),
                  
                  // Warnings Section
                  if (_criticalWarnings.isNotEmpty || _warnings.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _criticalWarnings.isNotEmpty 
                            ? Colors.red.shade50 
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _criticalWarnings.isNotEmpty 
                                    ? Icons.warning_amber 
                                    : Icons.info_outline,
                                color: _criticalWarnings.isNotEmpty 
                                    ? Colors.red 
                                    : Colors.orange,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _criticalWarnings.isNotEmpty 
                                    ? 'Alertes critiques' 
                                    : 'Avertissements',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _criticalWarnings.isNotEmpty 
                                      ? Colors.red 
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...(_criticalWarnings.isNotEmpty 
                              ? _criticalWarnings 
                              : _warnings).map((warning) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: _criticalWarnings.isNotEmpty 
                                          ? Colors.red.shade700
                                          : Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        warning['message'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _criticalWarnings.isNotEmpty 
                                              ? Colors.red.shade700
                                              : Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Subject Statistics Section
                  _buildSubjectStatistics(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent History
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Historique des séances',
                        style: TextStyle(
                          color: Color(0xFF000666),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Absences List
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_errorMessage != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchAbsences,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  else if (_absences.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty, size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Aucune séance enregistrée'),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _absences.map((absence) {
                        return _buildAbsenceCard(absence);
                      }).toList(),
                    ),
                ],
              ),
            ),
            
            // Top Bar
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color(0xCCFBF8FF),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF000666), Color(0xFF1A237E)],
                            ),
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: const Center(
                            child: Icon(Icons.school, color: Colors.white, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'FSB Bizerte',
                          style: TextStyle(
                            color: Color(0xFF000666),
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF000666)),
                      onPressed: () {
                        PdfService.generateAbsencesPdf(
                          nom: widget.nom,
                          prenom: widget.prenom,
                          absences: _absences,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 35),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Color(0xFFF3F2FE)),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  shadows: const [
                    BoxShadow(
                      color: Color(0x0F000666),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildNavItem('Accueil', 0, Icons.home),
                    _buildNavItem('Sessions', 1, Icons.calendar_today),
                    _buildNavItem('Profil', 2, Icons.person),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF94A3B8),
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsenceCard(Absence absence) {
    bool isPresent = absence.statut == 'present';
    bool isJustified = absence.statut == 'justifié';
    String statusText = isPresent ? 'PRÉSENT' : (isJustified ? 'JUSTIFIÉ' : 'ABSENT');
    Color statusColor = isPresent 
        ? const Color(0xFF006A60)
        : (isJustified ? const Color(0xFF5C1800) : const Color(0xFFBA1A1A));
    Color bgColor = isPresent
        ? const Color(0xFF85F6E5)
        : (isJustified ? const Color(0xFFFFDBD0) : const Color(0xFFFFDAD6));
    IconData statusIcon = isPresent ? Icons.check_circle : (isJustified ? Icons.assignment_late : Icons.cancel);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              color: const Color(0xFFE8E7F2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.book, color: const Color(0xFF1A237E), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  absence.matiere,
                  style: const TextStyle(
                    color: Color(0xFF1A1B23),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(absence.dateSeance),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      absence.heureDebut,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: ShapeDecoration(
              color: bgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 14),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
      DateTime dateTime = DateTime.parse(date);
      return '${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return months[month - 1];
  }
}