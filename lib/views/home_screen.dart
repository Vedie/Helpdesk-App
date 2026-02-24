import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';
import 'add_ticket_screen.dart';
import 'help_center_view.dart';
import '../widgets/custom_navbar.dart';
import '../services/hubspot_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = "Tous";
  static const Color blueONT = Color(0xFF1E3A8A); // CORRECTION ICI

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_name') ?? "Utilisateur";
  }

  // Fonction pour récupérer les tickets en fonction du filtre
  Stream<QuerySnapshot> _getTicketsStream(String userId) {
    Query query = FirebaseFirestore.instance
        .collection('tickets')
        .where('userId', isEqualTo: userId);

    // Filtre par statut
    if (_selectedFilter == "En attente") {
      query = query.where('status', isEqualTo: 'En attente');
    } else if (_selectedFilter == "En cours") {
      query = query.where('status', isEqualTo: 'En cours');
    } else if (_selectedFilter == "Résolus") {
      query = query.where('status', isEqualTo: 'Résolu');
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Mes Tickets",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: blueONT,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddTicketScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCenterView()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          FutureBuilder<String>(
            future: _getUserName(),
            builder: (context, snapshot) =>
                _buildHeader(snapshot.data ?? "..."),
          ),
          _buildFilters(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTicketsStream(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Erreur : ${snapshot.error}"));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                  );
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == "Tous"
                              ? "Aucun ticket trouvé"
                              : "Aucun ticket $_selectedFilter",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        if (_selectedFilter != "Tous") ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedFilter = "Tous";
                              });
                            },
                            child: const Text("Voir tous les tickets"),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final ticket = Ticket.fromMap(data, docs[index].id);
                    return _buildTicketCard(ticket);
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavbar(currentIndex: 0),
    );
  }

  Widget _buildHeader(String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Bienvenue, $userName",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "Comment pouvons-nous vous aider ?",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: InputDecoration(
              hintText: "Rechercher...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ["Tous", "En attente", "En cours", "Résolus"];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: filters
            .map(
              (label) => _filterChip(
                label,
                isSelected: label == _selectedFilter,
                onTap: () {
                  setState(() {
                    _selectedFilter = label;
                  });
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _filterChip(
    String label, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? blueONT : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? blueONT : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    Color impactColor = Colors.green;
    if (ticket.priority.contains("bloqué")) impactColor = Colors.red;
    if (ticket.priority.contains("pénible")) impactColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.id ?? "ONT-XX",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                  fontSize: 14,
                ),
              ),
              _statusBadge(ticket.status, _getStatusColor(ticket.status)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            "${ticket.category} • ${ticket.department}",
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const Divider(height: 25),
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: impactColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ticket.priority,
                  style: TextStyle(
                    color: impactColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    if (status == 'En attente') return const Color(0xFF64748B);
    if (status == 'Nouveau' || status == 'Ouvert')
      return const Color(0xFFD32F2F);
    if (status == 'En cours') return const Color(0xFFF57C00);
    if (status == 'Résolu') return const Color(0xFF1976D2);
    return const Color(0xFF1976D2);
  }
}
