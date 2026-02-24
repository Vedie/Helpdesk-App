import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _resetPasswordEmail; // Pour suivre l'email de réinitialisation

  bool get isLoading => _isLoading;
  String? get resetPasswordEmail => _resetPasswordEmail;

  // --- CONNEXION EMAIL/PASSWORD (ADMIN, TECH, USER) ---
  Future<String?> login(String email, String password) async {
    _setLoading(true);
    try {
      User? user = await _authService.loginWithEmail(email, password);
      if (user != null) {
        return await _authService.getUserRole(user.uid);
      }
    } catch (e) {
      debugPrint("Login Error: $e");
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // --- INSCRIPTION (UNIQUEMENT POUR LES EMPLOYÉS) ---
  Future<bool> register(String email, String password, String name) async {
    _setLoading(true);
    try {
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        await result.user!.updateDisplayName(name);
        await result.user!.reload();

        User? updatedUser = FirebaseAuth.instance.currentUser;
        await _authService.syncUserToFirestore(updatedUser!, customName: name);

        return true;
      }
    } catch (e) {
      debugPrint("Register Error: $e");
    } finally {
      _setLoading(false);
    }
    return false;
  }

  // --- CONNEXION GOOGLE (EMPLOYÉS UNIQUEMENT) ---
  Future<String?> loginWithGoogle() async {
    _setLoading(true);
    try {
      User? user = await _authService.signInWithGoogle();
      if (user != null) {
        return await _authService.getUserRole(user.uid);
      }
    } catch (e) {
      debugPrint("Google Login Error: $e");
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // --- NOUVEAU : CONNEXION GITHUB (REMPLACE FACEBOOK) ---
  Future<String?> loginWithGitHub() async {
    _setLoading(true);
    try {
      // Utilisation du provider GitHub
      GithubAuthProvider githubProvider = GithubAuthProvider();

      // On lance la connexion
      UserCredential userCredential = await FirebaseAuth.instance.signInWithProvider(githubProvider);
      User? user = userCredential.user;

      if (user != null) {
        // On synchronise l'utilisateur GitHub dans la collection 'users' de Firestore
        await _authService.syncUserToFirestore(user);
        // On récupère son rôle
        return await _authService.getUserRole(user.uid);
      }
    } catch (e) {
      debugPrint("GitHub Login Error: $e");
    } finally {
      _setLoading(false);
    }
    return null;
  }

  // --- DÉCONNEXION AMÉLIORÉE ---
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      debugPrint("Déconnexion réussie");
    } catch (e) {
      debugPrint("Erreur de déconnexion: $e");
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // --- RÉINITIALISATION DE MOT DE PASSE ---
  Future<Map<String, dynamic>> resetPassword(String email) async {
    _setLoading(true);
    _resetPasswordEmail = email;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Email de réinitialisation envoyé avec succès',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage = _getFirebaseErrorMessage(e);
      return {'success': false, 'message': errorMessage};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion.'};
    } finally {
      _setLoading(false);
    }
  }

  // --- VÉRIFICATION DE L'EMAIL ---
  Future<bool> checkEmailExists(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return false;
      return true;
    }
  }

  // --- GESTIONNAIRE D'ERREURS FIREBASE ---
  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun compte associé à cet email';
      case 'invalid-email':
        return "Format d'email invalide";
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion';
      default:
        return 'Une erreur est survenue: ${e.message ?? "Inconnue"}';
    }
  }

  void clearResetPasswordEmail() {
    _resetPasswordEmail = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}