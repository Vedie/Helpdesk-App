import 'package:flutter/material.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import '../utils/app_colors.dart';
  import '../controllers/auth_controller.dart';

  class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _authController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    String name = _nameController.text.trim();
    String email = _emailController.text.trim().toLowerCase();
    String pass = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", AppColors.redONT);
      return;
    }

    if (pass != confirmPass) {
      _showSnackBar("Les mots de passe ne correspondent pas", AppColors.redONT);
      return;
    }

    bool success = await _authController.register(email, pass, name);

    if (success && mounted) {
      // 💾 Sauvegarde locale du nom pour SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      _showSnackBar("Compte créé avec succès !", Colors.green);

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } else if (mounted) {
      _showSnackBar("Erreur lors de l'inscription", AppColors.redONT);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.blueONT)
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Text("Créer un compte",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.blueONT)),
              const Text("Rejoignez le HelpDesk de l'ONT", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              _buildField("Nom complet", Icons.person_outline, _nameController),
              const SizedBox(height: 16),
              _buildField("Email", Icons.email_outlined, _emailController),
              const SizedBox(height: 16),
              _buildField("Mot de passe", Icons.lock_outline, _passwordController, isPass: true),
              const SizedBox(height: 16),
              _buildField("Confirmer mot de passe", Icons.lock_clock_outlined, _confirmPasswordController, isPass: true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _authController.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueONT,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _authController.isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : const Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 25),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String hint, IconData icon, TextEditingController controller, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF7F8F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Déjà un compte ? "),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text("Se connecter", style: TextStyle(color: AppColors.redONT, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}