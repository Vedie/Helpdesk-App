import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/ticket.dart';

class TicketService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 1. GESTION DES TECHNICIENS (INGÉNIEURS)

  /// Récupère tous les techniciens enregistrés pour l'assignation
  static Future<List<Map<String, dynamic>>> getTechnicians() async {
    try {
      final snapshot = await _firestore.collection('technicians').get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print("Erreur récupération techniciens: $e");
      return [];
    }
  }

  /// Assigne un technicien et change le statut en "En cours"
  static Future<bool> assignTicket(
    String ticketId,
    String technicianName,
  ) async {
    try {
      // 1. Mise à jour du ticket dans Firestore
      await _firestore.collection('tickets').doc(ticketId).update({
        'status': 'En cours',
        'assignedTo': technicianName,
        'assignedAt': FieldValue.serverTimestamp(),
      });

      // 2. Récupérer le token du ticket pour envoyer la notification
      final ticketDoc = await _firestore
          .collection('tickets')
          .doc(ticketId)
          .get();
      final userToken = ticketDoc.data()?['userToken'];

      if (userToken != null) {
        // C'est ici qu'on déclenchera l'appel à l'API Cloud Functions
        // ou un service tiers pour envoyer la notification réelle.
        print("Notification prête à être envoyée au token: $userToken");
      }

      return true;
    } catch (e) {
      print("Erreur assignation: $e");
      return false;
    }
  }

  // 2. CRÉATION ET GESTION DES TICKETS

  /// Génère l'ID type ONT-26-01
  static Future<String> _generateCustomId() async {
    final docRef = _firestore.collection('counters').doc('tickets');
    final yearShort = DateTime.now().year.toString().substring(2);

    return await _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(docRef);

      int newValue = 1;
      if (snapshot.exists && snapshot.data() != null) {
        newValue =
            (snapshot.data() as Map<String, dynamic>)['currentValue'] + 1;
      }

      transaction.set(docRef, {'currentValue': newValue});
      String sequence = newValue.toString().padLeft(2, '0');

      return "ONT-$yearShort-$sequence";
    });
  }

  /// Crée le ticket avec ID forcé, Photo et Token de notification
  static Future<String?> createTicket(
    Ticket ticket, {
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      final String customId = await _generateCustomId();

      // Récupération du Token FCM du téléphone actuel
      String? userToken;
      try {
        userToken = await _fcm.getToken();
      } catch (e) {
        print("Erreur récupération Token: $e");
      }

      String? photoUrl;

      // Upload de l'image (File ou Bytes pour le Web)
      if (imageFile != null) {
        photoUrl = await _uploadImageFile(imageFile, customId);
      } else if (imageBytes != null) {
        photoUrl = await _uploadImageBytes(imageBytes, customId);
      }

      // Préparation finale des données
      final Map<String, dynamic> ticketData = ticket.toMap();
      ticketData['photoUrl'] = photoUrl;
      ticketData['createdAt'] = FieldValue.serverTimestamp();
      ticketData['userToken'] = userToken;

      // Création du document avec l'ID personnalisé
      await _firestore.collection('tickets').doc(customId).set(ticketData);

      return customId;
    } catch (e) {
      print("Erreur TicketService: $e");
      return null;
    }
  }

  // 3. RÉCUPÉRATION ET STATISTIQUES

  static Future<List<Ticket>> getUserTickets(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Ticket.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, int>> getTicketStats(String userId) async {
    try {
      final userTickets = await _firestore
          .collection('tickets')
          .where('userId', isEqualTo: userId)
          .get();

      int total = userTickets.docs.length;
      int open = userTickets.docs
          .where(
            (doc) =>
                doc['status'] == 'Ouvert' ||
                doc['status'] == 'En attente' ||
                doc['status'] == 'En cours',
          )
          .length;
      int closed = userTickets.docs
          .where((doc) => doc['status'] == 'Fermé')
          .length;

      return {'total': total, 'open': open, 'closed': closed};
    } catch (e) {
      return {'total': 0, 'open': 0, 'closed': 0};
    }
  }

  // 4. SUPPRESSION ET UPDATES

  static Future<bool> updateTicket(
    String ticketId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore.collection('tickets').doc(ticketId).update(updates);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteTicket(String ticketId, {String? photoUrl}) async {
    try {
      if (photoUrl != null && photoUrl.isNotEmpty) {
        await _storage.refFromURL(photoUrl).delete();
      }
      await _firestore.collection('tickets').doc(ticketId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Supprime tous les tickets de la collection
  static Future<bool> deleteAllTickets() async {
    try {
      final snapshot = await _firestore.collection('tickets').get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final photoUrl = data['photoUrl'] as String?;
        if (photoUrl != null && photoUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(photoUrl).delete();
          } catch (_) {}
        }
        batch.delete(doc.reference);
      }
      await batch.commit();
      return true;
    } catch (e) {
      print("Erreur suppression tous les tickets: $e");
      return false;
    }
  }

  // 5. HISTORIQUE ADMIN - Récupère tous les tickets pour l'historique global

  /// Récupère tous les tickets pour l'historique admin (tous statuts)
  static Future<List<Map<String, dynamic>>> getAllTicketsForHistory() async {
    try {
      final snapshot = await _firestore
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .get();

      // Cache pour les noms d'utilisateurs
      final Map<String, String> userNameCache = {};

      final List<Map<String, dynamic>> results = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        String userName = data['userName'] ?? '';

        // Si pas de userName, chercher dans la collection users
        if (userName.isEmpty && data['userId'] != null) {
          final userId = data['userId'] as String;
          if (userNameCache.containsKey(userId)) {
            userName = userNameCache[userId]!;
          } else {
            try {
              final userDoc = await _firestore
                  .collection('users')
                  .doc(userId)
                  .get();
              if (userDoc.exists) {
                userName =
                    (userDoc.data() as Map<String, dynamic>)['displayName'] ??
                    'Inconnu';
              } else {
                userName = 'Inconnu';
              }
              userNameCache[userId] = userName;
            } catch (_) {
              userName = 'Inconnu';
            }
          }
        }
        if (userName.isEmpty) userName = 'Inconnu';

        results.add({
          'id': doc.id,
          'titre': data['title'] ?? '',
          'tech': data['assignedTo'] ?? 'Non assigné',
          'user': data['department'] ?? 'Inconnu',
          'date': data['createdAt'] != null
              ? _formatDate((data['createdAt'] as Timestamp).toDate())
              : 'N/A',
          'dateRaw': data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : null,
          'duree': data['resolutionDuration'] ?? 'N/A',
          'photo': data['photoUrl'],
          'status': data['status'] ?? 'En attente',
          'category': data['category'] ?? '',
          'priority': data['priority'] ?? '',
          'description': data['description'] ?? '',
          'userName': userName,
        });
      }
      return results;
    } catch (e) {
      print("Erreur récupération tickets: $e");
      return [];
    }
  }

  /// Récupère tous les tickets fermés/résolus pour l'historique admin
  @Deprecated('Utilisez getAllTicketsForHistory() à la place')
  static Future<List<Map<String, dynamic>>> getClosedTickets() async {
    return getAllTicketsForHistory();
  }

  /// Formate une date en format français
  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Août',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }

  // --- HELPERS UPLOAD ---
  static Future<String?> _uploadImageFile(
    File imageFile,
    String customId,
  ) async {
    try {
      final ref = _storage.ref().child('tickets/images/$customId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  static Future<String?> _uploadImageBytes(
    Uint8List imageBytes,
    String customId,
  ) async {
    try {
      final ref = _storage.ref().child('tickets/images/$customId.jpg');
      await ref.putData(imageBytes);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }
}
