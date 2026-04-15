import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'etudiants/absences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FSB Sanctuary',
      theme: ThemeData(
        fontFamily: 'Inter',
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Use 10.0.2.2 for Android emulator, localhost for iOS, or your actual IP
    final url = Uri.parse('http://localhost/gest_absence_api/auth/login.php');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      // Check for success based on your PHP response structure
      if (data['success'] == 1) {
        final userData = data['data'];
        
        // Save user data locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userData['id']);
        await prefs.setString('nom', userData['nom']);
        await prefs.setString('prenom', userData['prenom']);
        await prefs.setString('email', userData['email']);
        await prefs.setString('role', userData['role']);
        
        // Save role-specific data
        if (userData['role'] == 'etudiant') {
          await prefs.setInt('etudiantId', userData['etudiant_id']);
          await prefs.setInt('classeId', userData['classe_id']);
          await prefs.setString('classeNom', userData['classe_nom']);
        } else if (userData['role'] == 'enseignant') {
          await prefs.setInt('enseignantId', userData['enseignant_id']);
          await prefs.setString('specialite', userData['specialite']);
        }
        
        if (mounted) {
          // Navigate based on role
          if (userData['role'] == 'etudiant') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AbsencesPage(
                  etudiantId: userData['etudiant_id'], // Use etudiant_id, not user id
                  nom: userData['nom'],
                  prenom: userData['prenom'],
                ),
              ),
            );
          } else if (userData['role'] == 'enseignant') {
            // Navigate to teacher dashboard (you'll create this)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Teacher dashboard coming soon')),
            );
          } else if (userData['role'] == 'admin') {
            // Navigate to admin dashboard (you'll create this)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Admin dashboard coming soon')),
            );
          }
        }
      } else {
        setState(() {
          _errorMessage = data['message'] ?? 'Login failed';
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _errorMessage = "Erreur de connexion au serveur. Vérifiez votre connexion.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo and Title
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 30, offset: Offset(0, 8))
                      ],
                    ),
                    child: const Icon(Icons.school, size: 48, color: Color(0xFF1A237E)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FSB Sanctuary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF000666),
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Access your academic workspace and\ndepartment resources',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xCC454652), fontSize: 14),
                  ),
                  const SizedBox(height: 48),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x141A237E), blurRadius: 64, offset: Offset(0, 32))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email Address', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE8E7F2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'student@fsb.u-carthage.tn',
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('Forgot Password?', style: TextStyle(color: Color(0xFF1A237E), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFE8E7F2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: '••••••••••••',
                          ),
                        ),
                        
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                        ],

                        const SizedBox(height: 32),
                        
                        // Login Button
                        GestureDetector(
                          onTap: _isLoading ? null : _login,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF000666), Color(0xFF1A237E)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: _isLoading 
                                ? const SizedBox(
                                    height: 20, width: 20, 
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                : const Text(
                                    'Login to Portal',
                                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}