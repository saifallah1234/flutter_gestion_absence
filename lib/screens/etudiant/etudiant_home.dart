// lib/screens/etudiant/etudiant_home.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/absence.dart';
import '../../models/etudiant.dart';
import '../../models/notification.dart';
import 'etudiant_absences.dart';
import 'etudiant_profil.dart';
import 'dart:async';


class EtudiantHomeScreen extends StatefulWidget {
  final Etudiant etudiant;

  const EtudiantHomeScreen({
    super.key,
    required this.etudiant,
  });

  @override
  State<EtudiantHomeScreen> createState() => _EtudiantHomeScreenState();
}

class _EtudiantHomeScreenState extends State<EtudiantHomeScreen> {
  List<Map<String, dynamic>> _recentSeances = [];
  Map<String, dynamic> _statistics = {};
  List<NotificationModel> _recentNotifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;
  Timer? _notificationTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startNotificationPolling();
  }
  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }

  void _startNotificationPolling() {
    // Vérifier les nouvelles notifications toutes les 30 secondes
    _notificationTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotifications();
      }
    });
  }
   

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.wait([
      _loadAbsencesData(),
      _loadNotifications(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAbsencesData() async {
    final response = await ApiService.getEtudiantDashboard(widget.etudiant.id);
    
    if (response['success'] == 1 && mounted) {
      final data = response['data'];
      setState(() {
        _recentSeances = (data['absences_list'] as List)
            .take(5)
            .map((item) => item as Map<String, dynamic>)
            .toList();
        _statistics = data['statistics'] ?? {};
      });
    } else if (mounted) {
      setState(() {
        _errorMessage = response['message'] ?? 'Erreur de chargement';
      });
    }
  }

  Future<void> _loadNotifications() async {
    final response = await ApiService.getNotifications(widget.etudiant.utilisateurId, 'etudiant');
    
    if (response['success'] == 1 && mounted) {
      final notifications = (response['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
      
      final oldUnreadCount = _unreadCount;
      
      setState(() {
        _recentNotifications = notifications.take(5).toList();
        _unreadCount = response['stats']?['unread'] ?? 0;
      });
      
      // Afficher une SnackBar si nouvelles notifications
      if (_unreadCount > oldUnreadCount && oldUnreadCount > 0) {
        final newCount = _unreadCount - oldUnreadCount;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$newCount nouvelle${newCount > 1 ? 's' : ''} notification${newCount > 1 ? 's' : ''}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Voir',
              onPressed: _showNotificationsDialog,
            ),
          ),
        );
      }
    }
  }

  // ✅ Remplacer les getters existants par ceux-ci :
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

  void _goToAbsences() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EtudiantAbsencesScreen(etudiant: widget.etudiant),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _goToProfil() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EtudiantProfilScreen(etudiant: widget.etudiant),
      ),
    ).then((_) => _loadDashboardData());
  }

  void _showNotificationsDialog() async {
    final response = await ApiService.getNotifications(widget.etudiant.utilisateurId, 'etudiant');
    if (response['success'] == 1 && mounted) {
      final notifications = (response['data'] as List)
          .map((item) => NotificationModel.fromJson(item))
          .toList();
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Notifications',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_unreadCount > 0)
                      TextButton(
                        onPressed: () async {
                          await ApiService.markAllNotificationsAsRead(
                            widget.etudiant.utilisateurId, 
                            'etudiant'
                          );
                          _loadNotifications();
                          Navigator.pop(context);
                          _showNotificationsDialog();
                        },
                        child: const Text('Tout marquer comme lu'),
                      ),
                  ],
                ),
              ),
              Expanded(
                    child: notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_off_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucune notification',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Les notifications d\'absence apparaîtront ici',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return _buildNotificationCard(notification);
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await ApiService.markNotificationAsRead(notification.id);
      setState(() {
        notification.isRead = true;
        _unreadCount--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour ${widget.etudiant.prenom} 👋',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF000666),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Étudiant',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, size: 28),
                          color: const Color(0xFF000666),
                          onPressed: _showNotificationsDialog,
                        ),
                        if (_unreadCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$_unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_errorMessage != null)
                  Center(
                    child: Column(
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadDashboardData,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                else ...[
                  _buildStatisticsCard(),
                  
                  const SizedBox(height: 20),
                  
                  if (getAbsenceRate() > 20) _buildWarningCard(),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Dernières séances',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000666),
                        ),
                      ),
                      TextButton(
                        onPressed: _goToAbsences,
                        child: const Text('Voir tout'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (_recentSeances.isEmpty)
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
                    ..._recentSeances.map((seance) => _buildSeanceCard(seance)),
                  
                  const SizedBox(height: 20),
                  
                  if (_recentNotifications.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF000666),
                          ),
                        ),
                        TextButton(
                          onPressed: _showNotificationsDialog,
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._recentNotifications.map((notification) => _buildNotificationCard(notification)),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
        borderRadius: BorderRadius.circular(20),
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
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
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
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
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
                      style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                    ),
                    const Text('TOTAL', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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

  Widget _buildWarningCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Attention : Taux d\'absence (${getAbsenceRate().toInt()}%) dépasse la limite de 20%',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
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

Widget _buildNotificationCard(NotificationModel notification) {
  return GestureDetector(
    onTap: () => _markAsRead(notification),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFF0F0FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: notification.type == 'justifie' 
              ? Colors.orange.withOpacity(0.3) 
              : notification.iconColor.withOpacity(0.2)
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: notification.iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(notification.icon, color: notification.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      notification.formattedDate,
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                    ),
                    if (notification.type == 'justifie') ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Justifiée',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: notification.iconColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    ),
  );
}

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.home, 'Accueil', true),
          _buildNavItem(Icons.calendar_today, 'Absences', false),
          _buildNavItem(Icons.person, 'Profil', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == 'Absences') _goToAbsences();
        else if (label == 'Profil') _goToProfil();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF000666) : Colors.grey.shade400,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF000666) : Colors.grey.shade400,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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