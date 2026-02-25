import 'package:cloud_firestore/cloud_firestore.dart';

class Ticket {
  final String? id;
  final String title;
  final String department;
  final String category;
  final String priority;
  final String description;
  final String? userId;
  final String? userName;
  final String status;
  final String? photoUrl;
  final String? userToken;
  final DateTime? createdAt;

  Ticket({
    this.id,
    required this.title,
    required this.department,
    required this.category,
    required this.priority,
    required this.description,
    this.userId,
    this.userName,
    required this.status,
    this.photoUrl,
    this.userToken,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'department': department,
      'category': category,
      'priority': priority,
      'description': description,
      'userId': userId,
      'userName': userName,
      'status': status,
      'photoUrl': photoUrl,
      'userToken': userToken,
      // Utilisation du Timestamp serveur pour un tri précis
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory Ticket.fromMap(Map<String, dynamic> map, String id) {
    return Ticket(
      id: id,
      title: map['title'] ?? '',
      department: map['department'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? '',
      description: map['description'] ?? '',
      userId: map['userId'],
      userName: map['userName'],
      status: map['status'] ?? 'En attente',
      photoUrl: map['photoUrl'],
      userToken: map['userToken'],
      // Conversion sécurisée du Timestamp Firestore vers DateTime Flutter
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}
