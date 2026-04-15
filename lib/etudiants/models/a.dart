import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StudentDashboardScreen extends StatefulWidget {
  final int studentId;
  final String studentName;
  
  const StudentDashboardScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Use 10.0.2.2 for emulator, or your PC's IP for real device
      final url = Uri.parse('http://localhost/gest_absence_api/etudiant/absences.php?id=${widget.studentId}');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == 1) {
          setState(() {
            _data = jsonData['data']; // This is a Map, not a List
          });
        } else {
          _errorMessage = jsonData['message'] ?? 'No data found';
        }
      } else {
        _errorMessage = 'Failed to load data';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper getters using the correct data structure
  List<dynamic> get _absencesList => _data['absences_list'] ?? [];
  
  Map<String, dynamic> get _statistics => _data['statistics'] ?? {};
  
  List<dynamic> get _warnings => _data['warnings'] ?? [];
  
  List<dynamic> get _criticalWarnings => _data['critical_warnings'] ?? [];
  
  Map<String, dynamic> get _student => _data['student'] ?? {};
  
  Map<String, dynamic> get _limits => _data['limits'] ?? {'max_absence_per_subject': 20, 'max_absence_total': 10};
  
  int get _totalAbsences => _statistics['absent'] ?? 0;
  
  int get _totalPresent => _statistics['present'] ?? 0;
  
  int get _totalSessions => _statistics['total_seances'] ?? 0;
  
  double get _attendanceRate => _statistics['overall_attendance_rate'] ?? 100.0;
  
  double get _absenceRate => _statistics['overall_absence_rate'] ?? 0.0;
  
  List<dynamic> get _subjectStats => _statistics['subject_stats'] ?? [];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Dashboard ${_student['prenom'] ?? widget.studentName} ${_student['nom'] ?? ''}'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: 'Vue globale'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Par matière'),
              Tab(icon: Icon(Icons.warning), text: 'Alertes'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDashboardData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildGlobalView(),
                      _buildSubjectView(),
                      _buildWarningsView(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildGlobalView() {
    final maxTotalAbsence = _limits['max_absence_total'] ?? 10;
    final isCritical = _absenceRate > maxTotalAbsence;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Main stats card
          Card(
            elevation: 4,
            color: isCritical ? Colors.red.shade50 : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    '📊 Statistiques générales',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 150,
                        width: 150,
                        child: CircularProgressIndicator(
                          value: _attendanceRate / 100,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _attendanceRate >= 90 ? Colors.green :
                            _attendanceRate >= 80 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${_attendanceRate.toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$_totalPresent / $_totalSessions séances',
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (isCritical)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '⚠️ Attention: Vous avez dépassé la limite de $maxTotalAbsence% d\'absences totales!',
                              style: TextStyle(color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Séances présentes',
                  _totalPresent.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Séances absentes',
                  _totalAbsences.toString(),
                  Colors.red,
                  Icons.cancel,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Recent absences
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Dernières absences',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (_totalAbsences == 0)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('✅ Aucune absence enregistrée!'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _absencesList.where((a) => a['statut'] == 'absent').take(5).length,
                      itemBuilder: (context, index) {
                        final absences = _absencesList.where((a) => a['statut'] == 'absent').toList();
                        final absence = absences[index];
                        return ListTile(
                          leading: const Icon(Icons.close, color: Colors.red),
                          title: Text(absence['matiere']),
                          subtitle: Text('${absence['date_seance']} - ${absence['heure_debut']}'),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectView() {
    if (_subjectStats.isEmpty) {
      return const Center(child: Text('Aucune donnée disponible'));
    }
    
    final maxPerSubject = _limits['max_absence_per_subject'] ?? 20;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _subjectStats.length,
      itemBuilder: (context, index) {
        final subject = _subjectStats[index];
        final absenceRate = subject['absence_rate'];
        final isDanger = absenceRate > maxPerSubject;
        final isWarning = absenceRate > maxPerSubject / 2;
        
        return Card(
          elevation: 2,
          color: isDanger ? Colors.red.shade50 : (isWarning ? Colors.orange.shade50 : Colors.white),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subject['matiere'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isDanger)
                      const Icon(Icons.warning, color: Colors.red),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: subject['attendance_rate'] / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    subject['attendance_rate'] >= 80 ? Colors.green :
                    subject['attendance_rate'] >= 60 ? Colors.orange : Colors.red,
                  ),
                  minHeight: 10,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('✅ Présent: ${subject['present']}'),
                    Text('❌ Absent: ${subject['absent']}'),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  "Taux d'absence: ${absenceRate.toStringAsFixed(1)}%",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDanger ? Colors.red : (isWarning ? Colors.orange : Colors.green),
                  ),
                ),
                if (isDanger)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠️ Vous avez dépassé la limite de $maxPerSubject%!',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarningsView() {
    if (_criticalWarnings.isEmpty && _warnings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              '✅ Bon travail!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Taux d'absence: ${_absenceRate.toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 5),
            Text(
              "Limite: ${_limits['max_absence_total']}%",
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_criticalWarnings.isNotEmpty) ...[
          const Text(
            '🚨 Alertes critiques',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 10),
          ..._criticalWarnings.map((warning) => _buildWarningCard(warning['message'], true)),
          const SizedBox(height: 20),
        ],
        if (_warnings.isNotEmpty) ...[
          const Text(
            '⚠️ Avertissements',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 10),
          ..._warnings.map((warning) => _buildWarningCard(warning['message'], false)),
        ],
      ],
    );
  }

  Widget _buildWarningCard(String message, bool isCritical) {
    return Card(
      color: isCritical ? Colors.red.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isCritical ? Icons.error : Icons.warning,
              color: isCritical ? Colors.red : Colors.orange,
              size: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCritical ? Colors.red.shade900 : Colors.orange.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}