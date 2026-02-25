import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
  }

  static Future<void> saveNotification({
    required String userId,
    required String title,
    required String body,
    required String ticketId,
  }) async {
    // Vérification de sécurité
    if (userId.isEmpty) {
      print("Erreur : Impossible d'envoyer une notif car le userId est vide !");
      return;
    }

    await FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'ticketId': ticketId,
      'timestamp': FieldValue.serverTimestamp(), // Firestore génère l'heure ici
      'isRead': false,
    });
  }
}