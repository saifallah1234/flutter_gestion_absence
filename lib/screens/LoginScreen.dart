import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/utilisateur.dart';

// IMPORTANT: Ajoutez cet import pour lier la page de l'enseignant
import './enseignant/enseignant_home.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.login(email, password);

    setState(() => _isLoading = false);

    if (response['status'] == 'Success') {
      Utilisateur user = Utilisateur.fromJson(response['user']);

      if (!mounted) return;

      // Role-based routing
      if (user.role == 'enseignant') {
        // Redirection vers la VRAIE page de l'enseignant
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EnseignantHomeScreen(user: user),
          ),
        );
      } else if (user.role == 'admin') {
        // TODO: Create AdminHomeScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espace Admin en cours de construction')),
        );
      } else if (user.role == 'etudiant') {
        // TODO: Create EtudiantHomeScreen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Espace Etudiant en cours de construction')),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Erreur de connexion')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.school_rounded,
                size: 80,
                color: Color(0xFF1A237E),
              ),
              const SizedBox(height: 24),
              const Text(
                'FSB Sanctuary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const Text(
                'Gestion des Absences',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// J'AI SUPPRIMÉ LE PLACEHOLDER ICI !