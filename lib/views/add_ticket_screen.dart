import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_navbar.dart';
import '../controllers/ticket_controller.dart';
import 'home_screen.dart';

class AddTicketScreen extends StatefulWidget {
  const AddTicketScreen({super.key});

  @override
  State<AddTicketScreen> createState() => _AddTicketScreenState();
}

class _AddTicketScreenState extends State<AddTicketScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage(TicketController ctrl, ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        File imageFile = File(image.path);
        ctrl.setImage(imageFile);
        _showSuccess("Image sélectionnée avec succès");
      }
    } catch (e) {
      _showError("Erreur accès appareil photo/galerie: $e");
    }
  }

  void _resetForm(TicketController ctrl) {
    ctrl.clear();
  }

  void _showSuccessDialog(String ticketId, TicketController ctrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 16),
              const Text(
                "Succès !",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Text(
                "Votre requête $ticketId a été transmise au département de services généraux.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    _resetForm(ctrl);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                  },
                  child: const Text("D'accord", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitTicket(TicketController ctrl) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Vous devez être connecté.");
      return;
    }

    if (ctrl.titleController.text.isEmpty ||
        ctrl.department == null ||
        ctrl.category == null ||
        ctrl.priority == null ||
        ctrl.descriptionController.text.isEmpty) {
      _showError("Veuillez remplir tous les champs obligatoires");
      return;
    }

    try {
      // GÉNÉRATION DE L'ID FORCÉ : ONT-26-XXXX
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String sequence = timestamp.substring(timestamp.length - 2);
      final String customTicketId = "ONT-26-$sequence";

      final String? resultId = await ctrl.submitTicket(
        userId: user.uid,
        customId: customTicketId, // Passage de l'ID forcé au controller
      );

      if (resultId != null) {
        if (mounted) _showSuccessDialog(resultId, ctrl);
      } else {
        _showError('Erreur lors de la création du ticket');
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketCtrl = Provider.of<TicketController>(context);
    const Color blueONT = Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24),
            decoration: const BoxDecoration(
              color: blueONT,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Nouveau Ticket", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("Signalez votre problème", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _inputLabel("Titre du problème *"),
                _textField(ticketCtrl.titleController, "Ex: PC ne s'allume plus"),
                const SizedBox(height: 20),
                _inputLabel("Votre Département *"),
                _buildDropdown(
                  ticketCtrl,
                  ["Administration", "Opérations touristiques", "Finance", "Informatique", "Logistique", "Autre"],
                  ticketCtrl.department,
                      (v) => ticketCtrl.setDepartment(v),
                ),
                const SizedBox(height: 20),
                _inputLabel("Nature du problème *"),
                _buildDropdown(
                  ticketCtrl,
                  ["Ordinateur en panne", "Imprimante défectueuse", "Problème Internet/Réseau", "Climatiseur en panne", "Problème éléctrique", "Maintenance générale"],
                  ticketCtrl.category,
                      (v) => ticketCtrl.setCategory(v),
                ),
                const SizedBox(height: 20),
                _inputLabel("À quel point êtes-vous bloqué ? *"),
                _buildDropdown(
                  ticketCtrl,
                  [
                    "Je suis totalement bloqué(e), je ne peux plus rien faire",
                    "Je peux travailler, mais c'est vraiment pénible",
                    "Tout va bien, c'est juste pour une petite amélioration",
                  ],
                  ticketCtrl.priority,
                      (v) => ticketCtrl.setPriority(v),
                ),
                const SizedBox(height: 20),
                _inputLabel("Description détaillée *"),
                _textField(ticketCtrl.descriptionController, "Détails du problème...", lines: 4),
                const SizedBox(height: 20),
                _inputLabel("Joindre une photo ${ticketCtrl.imageFile != null ? '(1 photo sélectionnée)' : ''}"),
                if (ticketCtrl.imageFile == null)
                  Row(
                    children: [
                      Expanded(child: _btnIcon(Icons.camera_alt, "Caméra", ticketCtrl.isLoading ? null : () => _pickImage(ticketCtrl, ImageSource.camera))),
                      const SizedBox(width: 10),
                      Expanded(child: _btnIcon(Icons.image, "Galerie", ticketCtrl.isLoading ? null : () => _pickImage(ticketCtrl, ImageSource.gallery))),
                    ],
                  )
                else
                  _imagePreviewWidget(ticketCtrl),
                if (ticketCtrl.uploadProgress != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(color: blueONT),
                        const SizedBox(height: 8),
                        Text(ticketCtrl.uploadProgress!),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: (ticketCtrl.isLoading) ? null : () => _submitTicket(ticketCtrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blueONT,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: ticketCtrl.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Créer le ticket", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavbar(currentIndex: 1),
    );
  }

  Widget _inputLabel(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
  );

  Widget _textField(TextEditingController controller, String h, {int lines = 1}) => TextField(
    controller: controller,
    maxLines: lines,
    decoration: InputDecoration(
      hintText: h,
      filled: true,
      fillColor: const Color(0xFFF5F6F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Widget _buildDropdown(TicketController ctrl, List<String> list, String? val, Function(String?) onCh) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(color: const Color(0xFFF5F6F9), borderRadius: BorderRadius.circular(12)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: val,
        isExpanded: true,
        hint: const Text("Sélectionnez"),
        items: list.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: ctrl.isLoading ? null : (value) => onCh(value),
      ),
    ),
  );

  Widget _btnIcon(IconData i, String l, VoidCallback? onPressed) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(i, color: Colors.white, size: 20),
    label: Text(l, style: const TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF475569), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  );

  Widget _imagePreviewWidget(TicketController ctrl) => Column(
    children: [
      Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(ctrl.imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                onPressed: ctrl.isLoading ? null : () => ctrl.setImage(null),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
      TextButton.icon(
        onPressed: ctrl.isLoading ? null : () => ctrl.setImage(null),
        icon: const Icon(Icons.delete, color: Colors.red),
        label: const Text("Supprimer la photo", style: TextStyle(color: Colors.red)),
      ),
    ],
  );
}