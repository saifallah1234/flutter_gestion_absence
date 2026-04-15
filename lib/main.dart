import 'package:flutter/material.dart';
import 'models/utilisateur.dart';
import 'screens/enseignant/enseignant_home.dart';
import 'etudiants/absences.dart';
import 'services/api_service.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
      },
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
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez renseigner l\'email et le mot de passe.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await ApiService.login(email, password);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response['success'] == 1) {
      final userData = response['data'] as Map<String, dynamic>;
      final user = Utilisateur.fromJson(userData);

      if (user.role == 'enseignant') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EnseignantHomeScreen(user: user),
          ),
        );
      } else if (user.role == 'etudiant') {
        final etudiantId = int.tryParse(userData['etudiant_id']?.toString() ?? '') ?? 0;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AbsencesPage(
              etudiantId: etudiantId,
              nom: user.nom,
              prenom: user.prenom,
            ),
          ),
        );
      } else if (user.role == 'admin') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espace administrateur non encore implémenté.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rôle non pris en charge: vérifiez votre compte.')),
        );
      }
    } else {
      setState(() {
        _errorMessage = response['message']?.toString() ?? 'Erreur de connexion';
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
                    'Gestion des absences pour votre établissement',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xCC454652), fontSize: 14),
                  ),
                  const SizedBox(height: 48),
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
                            hintText: 'email@example.com',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Se connecter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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