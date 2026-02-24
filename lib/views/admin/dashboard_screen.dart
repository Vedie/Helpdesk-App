import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/stat_card.dart';
import '../../services/notification_service.dart';
import '../../services/ticket_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // LOGIQUE : VALIDER L'ACHAT
  Future<void> _validatePurchase(
    BuildContext context,
    String docId,
    String userId,
    String title,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(docId).update({
        'status': 'Assigné',
        'needs': FieldValue.delete(),
      });

      await NotificationService.saveNotification(
        userId: userId,
        title: "Matériel Reçu 📦",
        body:
            "Le matériel pour votre ticket '$title' est arrivé. L'intervention reprend.",
        ticketId: docId,
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Achat validé. Le ticket est débloqué."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur validation achat: $e");
    }
  }

  // LOGIQUE : AFFICHER LES DETAILS D'UN TICKET
  void _showTicketDetails(
    BuildContext context,
    Map<String, dynamic> ticket,
    String docId,
  ) async {
    // Récupérer le nom du demandeur
    String demandeur = ticket['userName'] ?? '';
    if (demandeur.isEmpty && ticket['userId'] != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(ticket['userId'])
            .get();
        if (userDoc.exists) {
          demandeur =
              (userDoc.data() as Map<String, dynamic>)['displayName'] ??
              'Inconnu';
        } else {
          demandeur = 'Inconnu';
        }
      } catch (_) {
        demandeur = 'Inconnu';
      }
    }
    if (demandeur.isEmpty) demandeur = 'Inconnu';

    bool isBlocked = ticket['status'] == "Bloqué";

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Détails Ticket",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                      color: AppColors.blueONT.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.blueONT.withOpacity(0.3))
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tag, color: AppColors.blueONT, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        docId,
                        style: const TextStyle(
                            color: AppColors.blueONT,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.2
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _detailBadge(ticket['priority'] ?? 'Standard'),
                const SizedBox(height: 20),
                _infoText("Demandeur", demandeur),
                _infoText("Département", ticket['department'] ?? 'Général'),
                _infoText("Titre", ticket['title'] ?? 'N/A'),
                _infoText(
                  "Description",
                  ticket['description'] ?? 'Pas de description.',
                ),

                if (isBlocked) ...[
                  const SizedBox(height: 15),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: Colors.orange,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "MATÉRIEL REQUIS",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${ticket['needs'] ?? 'Non spécifié'}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _validatePurchase(
                              context,
                              docId,
                              ticket['userId'] ?? '',
                              ticket['title'] ?? 'Ticket',
                            ),
                            icon: const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "VALIDER L'ACHAT",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                  // PREUVE PHOTO
                const SizedBox(height: 20),
                const Text(
                  "PREUVE PHOTO :",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child:
                        (ticket['photoUrl'] != null && ticket['photoUrl'] != "")
                        ? Image.network(
                            ticket['photoUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          )
                        : const Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const Text(
                  "ASSIGNATION TECHNIQUE",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 10),
                // Logique Choix du technicien
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('technicians')
                      .snapshots(),
                  builder: (context, snapshot) {
                    List<Map<String, dynamic>> techList = [
                      {"name": "Non assigné", "uid": ""},
                    ];
                    if (snapshot.hasData) {
                      for (var d in snapshot.data!.docs) {
                        techList.add({
                          "name": d['name'] ?? 'Inconnu',
                          "uid": d.id,
                        });
                      }
                    }

                    String? currentValue = ticket['assignedTo'];
                    if (currentValue != null &&
                        !techList.any((t) => t['name'] == currentValue)) {
                      currentValue = "Non assigné";
                    }

                    return DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      value: currentValue ?? "Non assigné",
                      items: techList
                          .map(
                            (t) => DropdownMenuItem<String>(
                              value: t['name'].toString(),
                              child: Text(t['name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) async {
                        if (v != null && v != "Non assigné") {
                          final selectedTech = techList.firstWhere(
                            (e) => e['name'] == v,
                          );
                          await FirebaseFirestore.instance
                              .collection('tickets')
                              .doc(docId)
                              .update({
                                'assignedTo': v,
                                'assignedTechId':
                                    selectedTech['uid'],
                                'status': 'Assigné',
                              });

                          // Notification à l'employé (demandeur du ticket)
                          final employeeId = ticket['userId'] ?? '';
                          if (employeeId.isNotEmpty) {
                            await NotificationService.saveNotification(
                              userId: employeeId,
                              title: "Ticket Assigné 🛠️",
                              body:
                                  "Votre ticket '${ticket['title'] ?? 'Ticket'}' a été assigné au technicien $v.",
                              ticketId: docId,
                            );
                          }

                          if (context.mounted) Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
// Affichage des statistiques et des tickets dans le Dashbaord
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Row(
        children: [
          const SizedBox(width: 260, child: SideMenu(selectedIndex: 0)),
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tableau de Bord Admin",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildRealStatGrid(),
                        const SizedBox(height: 40),
                        _buildSectionTitle(
                          "ALERTES BLOCAGE (MATÉRIEL)",
                          Icons.shopping_cart_outlined,
                          Colors.orange,
                        ),
                        const SizedBox(height: 15),
                        _buildBlockedTicketsList(context),
                        const SizedBox(height: 40),
                        _buildSectionTitle(
                          "FLUX GÉNÉRAL DES TICKETS",
                          Icons.confirmation_number_outlined,
                          AppColors.blueONT,
                        ),
                        const SizedBox(height: 15),
                        _buildRealTicketsList(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: AppColors.blueONT,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "ONT ADMIN PANEL",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted)
                Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRealStatGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        final docs = snapshot.data!.docs;
        return Row(
          children: [
            Expanded(
              child: StatCard(
                title: "Total Tickets",
                value: docs.length.toString(),
                icon: Icons.mail,
                color: AppColors.blueONT,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: StatCard(
                title: "Bloqués",
                value: docs
                    .where((d) => d['status'] == "Bloqué")
                    .length
                    .toString(),
                icon: Icons.shopping_cart,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: StatCard(
                title: "En attente",
                value: docs
                    .where(
                      (d) =>
                          d['status'] == "Ouvert" ||
                          d['status'] == "En attente",
                    )
                    .length
                    .toString(),
                icon: Icons.hourglass_empty,
                color: AppColors.redONT,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: StatCard(
                title: "Résolus",
                value: docs
                    .where((d) => d['status'] == "Résolu")
                    .length
                    .toString(),
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlockedTicketsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .where('status', isEqualTo: 'Bloqué')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final blockedDocs = snapshot.data!.docs;
        if (blockedDocs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Center(
              child: Text(
                "Aucun matériel en attente.",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          );
        }

        return Column(
          children: blockedDocs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: Colors.orange.withOpacity(0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.orange),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.shopping_basket,
                  color: Colors.orange,
                ),
                title: Text(
                  data['title'] ?? 'Ticket',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Besoin : ${data['needs'] ?? 'Non précisé'}"),
                trailing: ElevatedButton(
                  onPressed: () => _showTicketDetails(context, data, doc.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text(
                    "Gérer",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // --- LOGIQUE : SUPPRIMER UN TICKET ---
  Future<void> _confirmDeleteTicket(
    BuildContext context,
    String docId,
    String? photoUrl,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer ce ticket ?"),
        content: const Text(
          "Cette action est irréversible. Voulez-vous vraiment supprimer ce ticket ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Supprimer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final success = await TicketService.deleteTicket(
        docId,
        photoUrl: photoUrl,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "Ticket supprimé." : "Erreur lors de la suppression.",
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // --- LOGIQUE : SUPPRIMER TOUS LES TICKETS ---
  Future<void> _confirmDeleteAllTickets(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer TOUS les tickets ?"),
        content: const Text(
          "Cette action est irréversible. Tous les tickets seront définitivement supprimés.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Tout supprimer",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final success = await TicketService.deleteAllTickets();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? "Tous les tickets ont été supprimés."
                  : "Erreur lors de la suppression.",
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRealTicketsList(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final tickets = snapshot.data!.docs;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildListHeader([
                      "ID",
                      "Titre",
                      "Demandeur",
                      "Département",
                      "Priorité",
                      "Status",
                      "Actions",
                    ]),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: tickets.isEmpty
                        ? null
                        : () => _confirmDeleteAllTickets(context),
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Tout supprimer",
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
              ...tickets
                  .map(
                    (doc) => _ticketItem(
                      context,
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _ticketItem(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
  ) {
    String status = data['status'] ?? 'Ouvert';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              id.length > 5 ? id.substring(0, 5) : id,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              data['title'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: _buildUserName(data['userName'], data['userId']),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data['department'] ?? '',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(flex: 2, child: _prioBadge(data['priority'] ?? 'Normale')),
          Expanded(flex: 2, child: _statusText(status)),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showTicketDetails(context, data, id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueONT,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      "Détails",
                      style: TextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () =>
                      _confirmDeleteTicket(context, id, data['photoUrl']),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: 20,
                  ),
                  tooltip: "Supprimer ce ticket",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPERS UI ---
  Widget _buildUserName(String? userName, String? userId) {
    if (userName != null && userName.isNotEmpty) {
      return Text(
        userName,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      );
    }
    if (userId == null || userId.isEmpty) {
      return const Text(
        'Inconnu',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('...', style: TextStyle(fontSize: 12));
        }
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          return Text(
            data?['displayName'] ?? 'Inconnu',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          );
        }
        return const Text(
          'Inconnu',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        );
      },
    );
  }

  Widget _statusText(String s) {
    Color c = (s == "Résolu")
        ? Colors.green
        : (s == "Bloqué"
              ? Colors.orange
              : (s == "Ouvert" ? Colors.red : AppColors.blueONT));
    return Text(
      s,
      style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  Widget _prioBadge(String p) {
    Color c = (p == "Haute")
        ? Colors.red
        : (p == "Moyenne" ? Colors.orange : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        p,
        style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  Widget _detailBadge(String p) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.blueONT.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      "Priorité: $p",
      style: const TextStyle(
        color: AppColors.blueONT,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    ),
  );

  Widget _infoText(String l, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontSize: 13),
        children: [
          TextSpan(
            text: "$l: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: v),
        ],
      ),
    ),
  );

  Widget _buildSectionTitle(String t, IconData i, Color c) => Row(
    children: [
      Icon(i, color: c, size: 18),
      const SizedBox(width: 10),
      Text(
        t,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    ],
  );

  Widget _buildListHeader(List<String> titles) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: titles
          .map(
            (t) => Expanded(
              flex: t == "Titre" ? 3 : 2,
              child: Text(
                t,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );
}
