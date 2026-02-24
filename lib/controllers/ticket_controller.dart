import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';

class TicketController extends ChangeNotifier {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? _selectedDepartment;
  String? _selectedCategory;
  String? _selectedPriority;
  File? _imageFile;
  bool _isLoading = false;
  String? _uploadProgress;

  String? get department => _selectedDepartment;
  String? get category => _selectedCategory;
  String? get priority => _selectedPriority;
  File? get imageFile => _imageFile;
  bool get isLoading => _isLoading;
  String? get uploadProgress => _uploadProgress;

  void setDepartment(String? value) {
    _selectedDepartment = value;
    notifyListeners();
  }

  void setCategory(String? value) {
    _selectedCategory = value;
    notifyListeners();
  }

  void setPriority(String? value) {
    _selectedPriority = value;
    notifyListeners();
  }

  void setImage(File? value) {
    _imageFile = value;
    notifyListeners();
  }

  void clear() {
    titleController.clear();
    descriptionController.clear();
    _selectedDepartment = null;
    _selectedCategory = null;
    _selectedPriority = null;
    _imageFile = null;
    _uploadProgress = null;
    notifyListeners();
  }

  Future<String?> _uploadImage(File imageFile, String userId) async {
    try {
      _uploadProgress = "0%";
      notifyListeners();
      String fileName =
          'tickets/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask = storageRef.putFile(imageFile);

      uploadTask.snapshotEvents.listen((snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        _uploadProgress = "${(progress * 100).toStringAsFixed(0)}%";
        notifyListeners();
      });

      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // --- MISE À JOUR ICI ---
  Future<String?> submitTicket({
    required String userId,
    required String customId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      String? photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage(_imageFile!, userId);
        if (photoUrl == null) {
          // Échec de l'upload, mais on peut continuer sans photo
          debugPrint("⚠️ Upload échoué, création du ticket sans photo");
        }
      }

      // Récupérer le nom de l'utilisateur
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'Utilisateur';

      // Création du ticket
      final ticket = Ticket(
        title: titleController.text.trim(),
        department: _selectedDepartment!,
        category: _selectedCategory!,
        priority: _selectedPriority!,
        description: descriptionController.text.trim(),
        userId: userId,
        userName: userName,
        status: 'En attente',
        photoUrl: photoUrl,
        userToken: null, // À remplir si nécessaire
      );

      // Préparation des données
      final Map<String, dynamic> ticketData = ticket.toMap();
      ticketData['createdAt'] = FieldValue.serverTimestamp();

      // Force l'ID personnalisé dans Firestore
      await FirebaseFirestore.instance
          .collection('tickets')
          .doc(customId)
          .set(ticketData);

      clear();
      return customId;
    } catch (e) {
      debugPrint("Erreur: $e");
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
