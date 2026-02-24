 import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) return null;

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      if (userCredential.user != null) {
        await syncUserToFirestore(userCredential.user!);
      }
      return userCredential.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> syncUserToFirestore(User user, {String? customName}) async {
    // Avant de créer un document dans 'users', on vérifie si l'utilisateur
    // n'existe pas déjà dans 'admins' ou 'technicians'
    String role = await getUserRole(user.uid);

    // Si c'est un admin ou un tech, on met juste à jour leur 'lastLogin' dans leur collection respective
    if (role == 'admin') {
      await _db.collection('admins').doc(user.uid).update({'lastLogin': FieldValue.serverTimestamp()});
      return;
    }
    if (role == 'tech') {
      await _db.collection('technicians').doc(user.uid).update({'lastLogin': FieldValue.serverTimestamp()});
      return;
    }

    // Sinon, on procède avec la collection 'users'
    DocumentReference userRef = _db.collection('users').doc(user.uid);
    DocumentSnapshot doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'displayName': customName ?? user.displayName ?? user.email?.split('@')[0] ?? "Utilisateur",
        'role': 'user',
        'platform': kIsWeb ? 'web' : 'mobile',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      await userRef.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  Future<User?> loginWithEmail(String email, String password) async {
    UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (result.user != null) await syncUserToFirestore(result.user!);
    return result.user;
  }

  // --- LOGIQUE DE DÉTECTION MULTI-COLLECTIONS ---
  Future<String> getUserRole(String uid) async {
    try {
      // 1. Chercher dans les Admins
      DocumentSnapshot adminDoc = await _db.collection('admins').doc(uid).get();
      if (adminDoc.exists) return 'admin';

      // 2. Chercher dans les Techniciens
      DocumentSnapshot techDoc = await _db.collection('technicians').doc(uid).get();
      if (techDoc.exists) return 'tech';

      // 3. Chercher dans les Utilisateurs (Employés)
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      if (userDoc.exists) return 'user';

      return 'user'; // Par défaut
    } catch (e) {
      return 'user';
    }
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      }
      await _auth.signOut();
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
    }
  }
}