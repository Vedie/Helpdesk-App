import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class TechHistoryScreen extends StatefulWidget {
  const TechHistoryScreen({super.key});

  @override
  State<TechHistoryScreen> createState() => _TechHistoryScreenState();
}

class _TechHistoryScreenState extends State<TechHistoryScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentTechId = FirebaseAuth.instance.currentUser?.uid ?? "";
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.redONT,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Historique des interventions",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Connexion réelle à Firestore
              stream: _firestore
                  .collection('tickets')
                  .where('assignedTechId', isEqualTo: _currentTechId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];

                // Filtrage : Uniquement Résolu/Bloqué + Recherche
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';
                  final title = (data['title'] ?? '').toString().toLowerCase();

                  bool matchesStatus =
                      (status == 'Résolu' || status == 'Bloqué');
                  bool matchesSearch = title.contains(
                    _searchQuery.toLowerCase(),
                  );

                  return matchesStatus && matchesSearch;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Aucun historique trouvé.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final ticketData =
                        filteredDocs[index].data() as Map<String, dynamic>;
                    final docId = filteredDocs[index].id;
                    return _buildHistoryCard(docId, ticketData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: TextField(
      onChanged: (value) => setState(() => _searchQuery = value),
      decoration: InputDecoration(
        hintText: "Rechercher par titre...",
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFFF7F8F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );

  Widget _buildHistoryCard(String docId, Map<String, dynamic> t) {
    bool isResolved = t['status'] == "Résolu";

    String dateString = "Date inconnue";
    if (t['createdAt'] != null) {
      DateTime dt = (t['createdAt'] as Timestamp).toDate();
      dateString = DateFormat('dd MMM yyyy').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        leading: Icon(
          isResolved ? Icons.check_circle : Icons.pause_circle_filled,
          color: isResolved ? Colors.green : Colors.orange,
        ),
        title: Text(
          t['title'] ?? 'Sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          "ID: ${docId.substring(0, 5)} • $dateString",
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isResolved
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            (t['status'] ?? 'Inconnu').toUpperCase(),
            style: TextStyle(
              color: isResolved ? Colors.green : Colors.orange,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _detailRow("DÉPARTEMENT", t['department'] ?? 'N/A'),
                const SizedBox(height: 10),
                const Text(
                  "DESCRIPTION",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  t['description'] ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),

                if (t['needs'] != null) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MATÉRIEL DEMANDÉ :",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t['needs'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String val) => Row(
    children: [
      Text(
        "$label : ",
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
      Text(
        val,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      ),
    ],
  );
}
