import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_navbar.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});


  static const Color blueONT = Color(0xFF1E3A8A);

  Future<void> _clearAllNotifications(String userId) async {
    final batch = FirebaseFirestore.instance.batch();
    final querySnapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  void _showDeleteDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Tout effacer ?"),
        content: const Text("Voulez-vous supprimer toutes vos notifications définitivement ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await _clearAllNotifications(userId);
              Navigator.pop(context);
            },
            child: const Text("Effacer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Utilisateur non connecté")));
    final String userId = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(context, userId),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: userId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Center(child: Text("Erreur de chargement"));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: blueONT));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    Timestamp? timestamp = data['timestamp'] as Timestamp?;
                    DateTime date = timestamp?.toDate() ?? DateTime.now();
                    String timeLabel = DateFormat('dd/MM HH:mm').format(date);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            // On change aussi la couleur de l'icône pour aller avec le bleu
                            backgroundColor: blueONT.withOpacity(0.1),
                            child: const Icon(Icons.notifications, color: blueONT, size: 20),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(data['title'] ?? "Notification", style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    Text(timeLabel, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(data['body'] ?? "", style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavbar(currentIndex: 2),
    );
  }

  Widget _buildHeader(BuildContext context, String userId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 16),
      decoration: const BoxDecoration(
        color: blueONT,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Notifications",
            style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => _showDeleteDialog(context, userId),
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text("Aucune notification pour le moment", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}