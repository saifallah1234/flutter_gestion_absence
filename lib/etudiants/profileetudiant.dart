import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'absences.dart';
import 'models/profile.dart';

class ProfileEtudiantPage extends StatefulWidget {
  final int etudiantId;
  final String nom;
  final String prenom;

  const ProfileEtudiantPage({
    super.key,
    required this.etudiantId,
    required this.nom,
    required this.prenom,
  });

  @override
  State<ProfileEtudiantPage> createState() => _ProfileEtudiantPageState();
}

class _ProfileEtudiantPageState extends State<ProfileEtudiantPage> {
  EtudiantProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedIndex = 2; // Profile tab selected

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost/gest_absence_api/etudiant/profil.php?id=${widget.etudiantId}');

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == 1) {
          setState(() {
            _profile = EtudiantProfile.fromJson(data['data']);
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Profile not found';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile';
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

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    if (index == 0 || index == 1) {
      // Navigate to Absences
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AbsencesPage(
            etudiantId: widget.etudiantId,
            nom: widget.nom,
            prenom: widget.prenom,
          ),
        ),
      );
    }
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
              padding: const EdgeInsets.only(top: 96, left: 24, right: 24, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_errorMessage != null)
                    Center(
                      child: Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchProfile,
                            child: const Text('Réessayer'),
                          ),
                        ],
                      ),
                    )
                  else if (_profile != null)
                    Column(
                      children: [
                        // Profile Header
                        Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 128,
                                  height: 128,
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF000666), Color(0xFF85F6E5)],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 4),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Color(0xFF000666),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF006A60),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${widget.prenom} ${widget.nom}',
                              style: const TextStyle(
                                color: Color(0xFF000666),
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _profile!.email,
                              style: const TextStyle(
                                color: Color(0xFF454652),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF85F6E5),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Text(
                                _profile!.classe.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF005048),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Personal Information Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x26C6C5D4)),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F2FE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.person_outline, color: Color(0xFF000666)),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Informations Personnelles',
                                    style: TextStyle(
                                      color: Color(0xFF000666),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              _buildInfoRow('NOM COMPLET', '${_profile!.prenom} ${_profile!.nom}'),
                              const SizedBox(height: 20),
                              _buildInfoRow('EMAIL', _profile!.email),
                              const SizedBox(height: 20),
                              _buildInfoRow('CLASSE', _profile!.classe),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Logout Button
                        GestureDetector(
                          onTap: _logout,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F2FE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Se déconnecter',
                                style: TextStyle(
                                  color: Color(0xFFBA1A1A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9999),
                      ),
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
                    _buildNavItem('Home', 0),
                    _buildNavItem('Sessions', 1),
                    _buildNavItem('Profile', 2),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        decoration: isSelected
            ? BoxDecoration(
                color: const Color(0xFFF3F2FE),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF1A237E) : const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF454652),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF1A1B23),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}