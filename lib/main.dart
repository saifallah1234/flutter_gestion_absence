import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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

    // Use 10.0.2.2 instead of localhost if using Android Emulator
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

      final data = jsonDecode(response.body);

      if (data['status'] == 'Success') {
        final user = data['user'];
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                nom: user['nom'],
                prenom: user['prenom'],
                role: user['role'],
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['message'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion au serveur.";
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
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 800),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Stack(
              children: [
                // Background Gradients (Kept from your UI)
                Positioned(
                  left: -96, top: 500,
                  child: Container(
                    width: 384, height: 384,
                    decoration: BoxDecoration(
                      color: const Color(0x0C000666),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                Positioned(
                  left: 102, top: -96,
                  child: Container(
                    width: 384, height: 384,
                    decoration: BoxDecoration(
                      color: const Color(0x3385F6E5),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                  ),
                ),
                
                // Main Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Logo and Title
                    Container(
                      width: 96, height: 96,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- HOME PAGE (Redirect Target) ---
class HomePage extends StatelessWidget {
  final String nom;
  final String prenom;
  final String role;

  const HomePage({
    super.key,
    required this.nom,
    required this.prenom,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Color(0xFF000666)),
            const SizedBox(height: 24),
            Text(
              'Bienvenue, $prenom $nom',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E7F2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}