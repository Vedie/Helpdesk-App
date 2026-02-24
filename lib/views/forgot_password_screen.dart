import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_colors.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    // Nettoyer l'email de réinitialisation dans le controller
    final authController = Provider.of<AuthController>(context, listen: false);
    authController.clearResetPasswordEmail();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Envoyer l'email de réinitialisation
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );

      final result = await authController.resetPassword(
        _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success']) {
        setState(() => _emailSent = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppColors.redONT,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur lors de la réinitialisation"),
            backgroundColor: AppColors.redONT,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Vérifier l'existence de l'email avant l'envoi
  Future<void> _checkEmailBeforeSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authController = Provider.of<AuthController>(
        context,
        listen: false,
      );
      final exists = await authController.checkEmailExists(
        _emailController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (!exists && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cet email n'est pas enregistré"),
            backgroundColor: AppColors.redONT,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Si l'email existe, procéder à l'envoi
        _resetPassword();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // En cas d'erreur, on tente quand même l'envoi
      _resetPassword();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.redONT),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mot de passe oublié",
          style: TextStyle(
            color: AppColors.redONT,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent ? _buildSuccessScreen() : _buildEmailForm(),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),

          // Icône et titre
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.redONT.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 50,
                color: AppColors.redONT,
              ),
            ),
          ),

          const SizedBox(height: 30),

          const Text(
            "Problème de connexion ?",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.redONT,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Saisissez votre adresse email. Vous recevrez un lien pour réinitialiser votre mot de passe.",
            style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.5),
          ),

          const SizedBox(height: 30),

          // Champ email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: "Adresse Email",
              hintText: "exemple@ont.tn",
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF7F8F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: AppColors.redONT),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Veuillez saisir votre email";
              }
              final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegExp.hasMatch(value)) {
                return "Format d'email invalide";
              }
              return null;
            },
          ),

          const SizedBox(height: 30),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.redONT,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Envoyer le lien",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // Lien retour
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Retour à la connexion",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 50),

        // Icône de succès
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 60,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 30),

        const Text(
          "Email envoyé !",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),

        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8F9),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                "Un email a été envoyé à :",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 5),
              Text(
                _emailController.text.trim(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.redONT,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Cliquez sur le lien dans l'email pour réinitialiser votre mot de passe. Si vous ne voyez pas l'email, vérifiez vos spams.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // Boutons
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {
              // Nettoyer avant de retourner
              final authController = Provider.of<AuthController>(
                context,
                listen: false,
              );
              authController.clearResetPasswordEmail();
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redONT,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "Retour à la connexion",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
              _emailController.clear();
            });
          },
          child: const Text(
            "Utiliser une autre adresse",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      ],
    );
  }
}
