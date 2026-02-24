import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_colors.dart';
import '../controllers/auth_controller.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'admin/dashboard_screen.dart';
import 'tech/tech_dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveUserLocally() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      String name =
          user.displayName ?? user.email?.split('@')[0] ?? "Utilisateur";
      await prefs.setString('user_name', name);
    }
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _navigateBasedOnRole(String role) {
    if (role == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else if (role == "tech") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const TechDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    String? role = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (role != null && mounted) {
      await _saveUserLocally();
      _navigateBasedOnRole(role);
    } else if (mounted) {
      _showError("Identifiants incorrects ou compte inexistant");
    }
  }

  void _handleGoogleLogin() async {
    String? role = await _authController.loginWithGoogle();

    if (role != null && mounted) {
      if (role == "admin" || role == "tech") {
        await FirebaseAuth.instance.signOut();
        _showError("Accès réservé. Utilisez vos identifiants professionnels.");
        return;
      }
      await _saveUserLocally();
      _navigateBasedOnRole(role);
    }
  }

  void _handleGitHubLogin() async {
    String? role = await _authController.loginWithGitHub();

    if (role != null && mounted) {
      if (role == "admin" || role == "tech") {
        await FirebaseAuth.instance.signOut();
        _showError("Accès réservé. Utilisez vos identifiants professionnels.");
        return;
      }
      await _saveUserLocally();
      _navigateBasedOnRole(role);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.redONT,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // Logo ONT
              Image.asset(
                'assets/images/logo_ont.png',
                height: 110,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business_center,
                  size: 70,
                  color: AppColors.redONT,
                ),
              ),

              const Text(
                "HelpDesk ONT",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.redONT,
                ),
              ),

              const Text(
                "Office National du Tourisme",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 40),

              _buildTextField(
                "Adresse Email",
                Icons.email_outlined,
                _emailController,
              ),

              const SizedBox(height: 16),

              _buildTextField(
                "Mot de passe",
                Icons.lock_outline,
                _passwordController,
                isObscure: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _handleForgotPassword,
                  child: const Text(
                    "Mot de passe oublié ?",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed:
                  _authController.isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redONT,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _authController.isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Se connecter",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "OU",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 25),

              // Bouton Google
              _buildSocialButton(
                "Continuer avec Google",
                const Icon(Icons.g_mobiledata,
                    color: Color(0xFF4285F4), size: 28),
                const Color(0xFF4285F4),
                _handleGoogleLogin,
              ),

              const SizedBox(height: 12),

              // Bouton GitHub
              _buildSocialButton(
                "Continuer avec GitHub",
                Image.asset(
                  'assets/images/github.png',
                  height: 24,
                  errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.code,
                      color: Color(0xFF24292E)),
                ),
                const Color(0xFF24292E),
                _handleGitHubLogin,
              ),

              const SizedBox(height: 40),

              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      String hint,
      IconData icon,
      TextEditingController controller,
      {bool isObscure = false}) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true,
        fillColor: const Color(0xFFF7F8F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildSocialButton(
      String label,
      Widget iconWidget,
      Color color,
      VoidCallback onTap,
      ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: iconWidget,
        label: Text(
          label,
          style:
          TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Pas encore de compte ? "),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const RegisterScreen()),
          ),
          child: const Text(
            "S'inscrire",
            style: TextStyle(
              color: AppColors.redONT,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}