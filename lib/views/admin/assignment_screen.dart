import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../widgets/side_menu.dart';
import '../../services/ticket_service.dart';
import '../../services/notification_service.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Map pour stocker la sélection de tech pour chaque ticket individuellement
  final Map<String, String?> _selectedTechsPerTicket = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Row(
        children: [
          const SizedBox(width: 260, child: SideMenu(selectedIndex: 1)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Gestion des Assignations",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("Distribuez les tickets aux techniciens disponibles",
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- TICKETS EN ATTENTE ---
                        Expanded(
                          flex: 2,
                          child: _buildAssignmentBox("Tickets en attente", _buildRealPendingList()),
                        ),
                        const SizedBox(width: 30),
                        // --- ÉTAT DES TECHNICIENS ---
                        Expanded(
                          flex: 1,
                          child: _buildAssignmentBox("Techniciens Terrain", _buildRealTechStatusList()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentBox(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.blueONT)),
          const Divider(height: 30),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildRealPendingList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('tickets')
          .where('status', isEqualTo: 'En attente')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun ticket en attente", style: TextStyle(color: Colors.grey)));
        }

        final tickets = snapshot.data!.docs;

        return ListView.builder(
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final t = tickets[index].data() as Map<String, dynamic>;
            final String docId = tickets[index].id;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docId, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.blueONT, fontSize: 12)),
                        Text(t['title'] ?? 'Sans titre', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text("Dép: ${t['department']}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        _prioBadge(t['priority'] ?? ''),
                      ],
                    ),
                  ),
                  _buildAssignAction(docId, t),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _prioBadge(String prio) {
    bool isUrgent = prio.toLowerCase().contains("bloqué");
    return Container(
      margin: const EdgeInsets.only(top: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: isUrgent ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(isUrgent ? "URGENT" : "STANDARD", style: TextStyle(color: isUrgent ? Colors.red : Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAssignAction(String ticketId, Map<String, dynamic> ticketData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('technicians').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final techs = snapshot.data!.docs;

        return Row(
          children: [
            DropdownButton<String>(
              hint: const Text("Choisir tech", style: TextStyle(fontSize: 12)),
              value: _selectedTechsPerTicket[ticketId],
              underline: const SizedBox(),
              items: techs.map((doc) {
                final name = doc['name'] as String;
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedTechsPerTicket[ticketId] = val),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _selectedTechsPerTicket[ticketId] == null
                  ? null
                  : () async {
                String techName = _selectedTechsPerTicket[ticketId]!;

                // 1. Mise à jour du ticket
                bool success = await TicketService.assignTicket(ticketId, techName);

                if (success) {
                  // 2. ENVOI DE LA NOTIFICATION À L'EMPLOYÉ
                  await NotificationService.saveNotification(
                    userId: ticketData['userId'] ?? "",
                    title: "Technicien Assigné 🛠️",
                    body: "L'ingénieur $techName s'occupe de votre ticket : ${ticketData['title']}",
                    ticketId: ticketId,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Ticket $ticketId assigné et employé notifié !"), backgroundColor: Colors.green),
                    );
                    setState(() => _selectedTechsPerTicket.remove(ticketId));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueONT, elevation: 0),
              child: const Text("OK", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealTechStatusList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('technicians').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final techs = snapshot.data!.docs;

        return ListView.builder(
          itemCount: techs.length,
          itemBuilder: (context, index) {
            final tech = techs[index].data() as Map<String, dynamic>;
            final bool isAvailable = tech['status'] == "Actif";

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: (isAvailable ? Colors.green : Colors.orange).withOpacity(0.1),
                child: Icon(Icons.person, color: isAvailable ? Colors.green : Colors.orange),
              ),
              title: Text(tech['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text(tech['email'] ?? '', style: const TextStyle(fontSize: 11)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: (isAvailable ? Colors.green : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5)
                ),
                child: Text(
                    isAvailable ? "DISPO" : "OCCUPÉ",
                    style: TextStyle(color: isAvailable ? Colors.green : Colors.orange, fontSize: 9, fontWeight: FontWeight.bold)
                ),
              ),
            );
          },
        );
      },
    );
  }
}