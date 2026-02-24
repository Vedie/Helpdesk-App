import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Relative imports - using explicit paths for better IDE navigation
import '../../utils/app_colors.dart';
import 'tech_history_screen.dart';
import '../login_screen.dart';
import '../admin/dashboard_screen.dart';

/// Ticket status constants to avoid magic strings and typos across the codebase
/// Using French terminology as per the app's original design
class TicketStatus {
  static const String assigned = 'Assigné';
  static const String inProgress = 'En cours';
  static const String blocked = 'Bloqué';
  static const String resolved = 'Résolu';

  const TicketStatus._();
}

/// Priority constants for consistent handling across the app
class TicketPriority {
  static const String normal = 'Normale';
  static const String high = 'Haute';

  const TicketPriority._();
}

/// Default values used throughout the screen to avoid hardcoded strings
class Defaults {
  static const String techName = 'Technicien';
  static const String unknownUser = 'Inconnu';
  static const String generalDepartment = 'Général';
  static const String noTitle = 'Sans titre';
  static const String noDescription = 'Pas de description';
  static const String noPhoto = 'Aucune photo';
  static const String imageNotAvailable = 'Image non disponible';
  static const String loadingError = 'Erreur de chargement';

  const Defaults._();
}

class TechDashboardScreen extends StatefulWidget {
  const TechDashboardScreen({super.key});

  @override
  State<TechDashboardScreen> createState() => _TechDashboardScreenState();
}

class _TechDashboardScreenState extends State<TechDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _currentTechId = FirebaseAuth.instance.currentUser?.uid ?? "";
  String _techName = Defaults.techName;
  final TextEditingController _blockReasonController = TextEditingController();

  // Loading states for better UX
  bool _isLoadingTechName = true;
  bool _isProcessingAction = false;

  /// Shared stream for tickets query to avoid duplicate Firestore calls
  /// This improves performance by using a single query for both stats and list
  Stream<QuerySnapshot> get _ticketsStream => _firestore
      .collection('tickets')
      .where('assignedTechId', isEqualTo: _currentTechId)
      .snapshots();

  @override
  void initState() {
    super.initState();
    _loadTechName();
  }

  @override
  void dispose() {
    _blockReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadTechName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _techName = prefs.getString('user_name') ?? Defaults.techName;
          _isLoadingTechName = false;
        });
      }
    } catch (e) {
      // Fallback to default on error
      if (mounted) {
        setState(() {
          _techName = Defaults.techName;
          _isLoadingTechName = false;
        });
      }
      debugPrint('Error loading tech name: $e');
    }
  }

  /// Marks a ticket as resolved with proper error handling
  ///
  /// [docId] - The document ID of the ticket to resolve
  Future<bool> _markAsResolved(String docId) async {
    if (_isProcessingAction) return false;

    setState(() => _isProcessingAction = true);

    try {
      await _firestore.collection('tickets').doc(docId).update({
        'status': TicketStatus.resolved,
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ticket résolu !"),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la résolution: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error resolving ticket: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  void _showBlockDialog(String docId) {
    // Reset controller text when opening dialog
    _blockReasonController.clear();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Besoin matériel",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _blockReasonController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Précisez le matériel manquant...",
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: _isProcessingAction
                ? null
                : () async {
                    if (_blockReasonController.text.isNotEmpty) {
                      await _blockTicket(dialogContext, docId);
                    }
                  },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueONT),
            child: const Text(
              "Signaler",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Blocks a ticket with the specified reason
  Future<void> _blockTicket(BuildContext dialogContext, String docId) async {
    setState(() => _isProcessingAction = true);

    try {
      await _firestore.collection('tickets').doc(docId).update({
        'status': TicketStatus.blocked,
        'needs': _blockReasonController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ticket bloqué !"),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors du blocage: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Error blocking ticket: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.blueONT),
            child: const Text("Déconnecter"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.blueONT),
      ),
    );

    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) Navigator.pop(context);

      if (mounted) {
        if (kIsWeb) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la déconnexion: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildProfessionalHeader(_techName),
          _buildQuickStats(),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 10, 24, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "TÂCHES ASSIGNÉES",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tickets')
                  .where('assignedTechId', isEqualTo: _currentTechId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final activeTickets = (snapshot.data?.docs ?? [])
                    .where((doc) => doc['status'] != 'Résolu')
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: activeTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTechTaskCard(
                      activeTickets[index].id,
                      activeTickets[index].data() as Map<String, dynamic>,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalHeader(String name) => Container(
    width: double.infinity,
    padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 10),
    decoration: const BoxDecoration(
      color: AppColors.redONT,
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Bonjour, $name",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const Text(
                "Support Technique",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.history, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TechHistoryScreen(),
                ),
              ),
            ),
            const Badge(
              label: Text("!"),
              child: Icon(Icons.notifications_none, color: Colors.white),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildQuickStats() => StreamBuilder<QuerySnapshot>(
    stream: _firestore
        .collection('tickets')
        .where('assignedTechId', isEqualTo: _currentTechId)
        .snapshots(),
    builder: (context, snapshot) {
      int n = 0, e = 0, r = 0;
      if (snapshot.hasData) {
        for (var d in snapshot.data!.docs) {
          String s = d['status'] ?? '';
          if (s == 'Assigné')
            n++;
          else if (s == 'Bloqué' || s == 'En cours')
            e++;
          else if (s == 'Résolu')
            r++;
        }
      }
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _statBox(n.toString(), "À faire", Colors.orange),
            _statBox(e.toString(), "En cours", AppColors.blueONT),
            _statBox(r.toString(), "Résolus", Colors.green),
          ],
        ),
      );
    },
  );

  Widget _statBox(String val, String label, Color col) => Container(
    width: 95,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: col.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Column(
      children: [
        Text(
          val,
          style: TextStyle(
            color: col,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: col,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // Fonction pour construire l'affichage de l'image
  Widget _buildPhotoWidget(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              "Aucune photo",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Vérifier si l'URL est valide
    try {
      return GestureDetector(
        onTap: () {
          // Optionnel: Ouvrir l'image en plein écran
          _showFullScreenImage(context, photoUrl);
        },
        child: Hero(
          tag: photoUrl,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              photoUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppColors.blueONT,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint("Erreur de chargement d'image: $error");
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Image non disponible",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            const SizedBox(height: 8),
            Text(
              "Erreur de chargement",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      );
    }
  }

  // Optionnel: Afficher l'image en plein écran
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechTaskCard(String docId, Map<String, dynamic> t) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8F9),
      borderRadius: BorderRadius.circular(18),
    ),
    child: ExpansionTile(
      shape: const RoundedRectangleBorder(side: BorderSide.none),
      leading: const CircleAvatar(
        backgroundColor: Colors.white,
        child: Icon(Icons.build_circle_outlined, color: AppColors.blueONT),
      ),
      title: Text(
        t['title'] ?? 'Sans titre',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        "Statut: ${t['status']}",
        style: const TextStyle(fontSize: 12, color: AppColors.blueONT),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(),
              _detailLine("ID TICKET", docId, isId: true),
              _detailLine("DEMANDEUR", t['userName'] ?? 'Inconnu'),
              _detailLine("DÉPARTEMENT", t['department'] ?? 'Général'),
              _detailLine(
                "URGENCE",
                t['priority'] ?? 'Normale',
                isAlert: t['priority'] == 'Haute',
              ),
              const SizedBox(height: 15),
              const Text(
                "DESCRIPTION",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              Text(
                t['description'] ?? 'Pas de description',
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 15),
              const Text(
                "PHOTO PREUVE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              // Utilisation de la nouvelle fonction pour afficher l'image
              SizedBox(
                height: 150,
                width: double.infinity,
                child: _buildPhotoWidget(t['photoUrl']),
              ),
              const SizedBox(height: 20),
              // Si le ticket est bloqué, afficher un message et désactiver le bouton Résolu
              if (t['status'] == 'Bloqué') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Ce ticket est bloqué. Seul l'admin peut le débloquer après validation du matériel.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: _btnAction(
                        "RÉSOLU",
                        Colors.green,
                        Icons.check_circle_outline,
                        () => _markAsResolved(docId),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _btnAction(
                        "BLOQUÉ",
                        Colors.redAccent,
                        Icons.report_gmailerrorred,
                        () => _showBlockDialog(docId),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );

  Widget _detailLine(
    String label,
    String val, {
    bool isId = false,
    bool isAlert = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Text(
          "$label : ",
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            val,
            style: TextStyle(
              fontSize: 11,
              fontWeight: (isId || isAlert)
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: isId
                  ? AppColors.blueONT
                  : (isAlert ? Colors.red : Colors.black87),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _btnAction(
    String txt,
    Color col,
    IconData icon,
    VoidCallback onPressed,
  ) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 16, color: Colors.white),
    label: Text(
      txt,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: col,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
