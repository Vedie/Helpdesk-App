import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../utils/app_colors.dart';
import '../../widgets/side_menu.dart';

class EngineersScreen extends StatefulWidget {
  const EngineersScreen({super.key});

  @override
  State<EngineersScreen> createState() => _EngineersScreenState();
}

class _EngineersScreenState extends State<EngineersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Création d'un nouveau Technicien
  Future<void> _addEngineerToFirestore() async {
    // 1. Vérifications de base
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passController.text.isEmpty) {
      _showSnackBar("Veuillez remplir tous les champs", Colors.orange);
      return;
    }
    if (_passController.text != _confirmPassController.text) {
      _showSnackBar("Les mots de passe ne correspondent pas", Colors.red);
      return;
    }
    if (_passController.text.length < 6) {
      _showSnackBar("Le mot de passe doit faire au moins 6 caractères", Colors.orange);
      return;
    }

    try {
      // 2. Création d'une instance Firebase temporaire
      // Cela permet de créer un compte sans déconnecter l'Admin actuel
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'TempApp',
        options: Firebase.app().options,
      );

      // 3. Création dans Authentication
      UserCredential userCredential = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // 4. Création du document dans Firestore avec le même UID
      await _firestore.collection('technicians').doc(uid).set({
        "uid": uid,
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "status": "Actif",
        "role": "tech", // Très important pour la redirection au login
        "createdAt": FieldValue.serverTimestamp(),
      });

      // 5. Nettoyage de l'instance temporaire
      await tempApp.delete();

      // 6. Reset des champs et fermeture du dialogue
      _nameController.clear();
      _emailController.clear();
      _passController.clear();
      _confirmPassController.clear();

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar("Technicien créé et accès activé !", Colors.green);
      }
    } catch (e) {
      debugPrint("Erreur lors de la création : $e");
      _showSnackBar("Erreur : ${e.toString()}", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  // Suppression d'un Technicien
  void _confirmDelete(String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer ?"),
        content: Text("Voulez-vous vraiment retirer $name du système ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
              onPressed: () async {
                // Note : Cela supprime de Firestore.
                // Pour supprimer aussi de Auth, il faudrait une Cloud Function.
                await _firestore.collection('technicians').doc(docId).delete();
                if (mounted) Navigator.pop(context);
                _showSnackBar("Technicien supprimé", Colors.black);
              },
              child: const Text("Supprimer", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showAddEngineerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Nouveau Technicien", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("Nom Complet", Icons.person_outline, _nameController),
                _buildField("Email Professionnel", Icons.email_outlined, _emailController),
                _buildField("Mot de passe", Icons.lock_outline, _passController, isPass: true),
                _buildField("Confirmer mot de passe", Icons.lock_reset, _confirmPassController, isPass: true),
                const Text(
                  "L'identifiant sera créé automatiquement dans le système d'authentification.",
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                )
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: _addEngineerToFirestore,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueONT),
            child: const Text("Créer l'accès", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Row(
        children: [
          const SizedBox(width: 260, child: SideMenu(selectedIndex: 3)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Gestion des Ingénieurs",
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          Text("Gérez les comptes techniques et les accès à l'application mobile",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddEngineerDialog,
                        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                        label: const Text("Ajouter un Technicien", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redONT,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Expanded(child: _buildEngineersList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('technicians').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final docs = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: [
              _buildHeaderRow(),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;
                    return _engineerRow(docId, data);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
    child: Row(
      children: const [
        Expanded(flex: 3, child: Text("NOM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
        Expanded(flex: 3, child: Text("EMAIL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
        Expanded(flex: 2, child: Text("STATUT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
        Expanded(flex: 1, child: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12))),
      ],
    ),
  );

  Widget _engineerRow(String docId, Map<String, dynamic> eng) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade50))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(eng['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(flex: 3, child: Text(eng['email'] ?? '')),
          Expanded(flex: 2, child: _statusBadge(eng['status'] ?? 'Actif')),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _confirmDelete(docId, eng['name'] ?? '')
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: status == "Actif" ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8)
    ),
    child: Text(status, style: TextStyle(color: status == "Actif" ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  Widget _buildField(String hint, IconData icon, TextEditingController controller, {bool isPass = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.blueONT),
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    ),
  );
}