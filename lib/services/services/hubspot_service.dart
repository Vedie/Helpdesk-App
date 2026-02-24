import 'package:flutter/material.dart'; 
import 'dart:convert';
import 'package:http/http.dart' as http;

class HubSpotService {
  // 🔑 VOTRE TOKEN PERSONNEL (copié-collé depuis HubSpot)
  static const String _accessToken = 'victorina';
  static const String _baseUrl = 'https://api.hubapi.com/crm/v3/objects/tickets';

  // 📋 Headers communs
  static Map<String, String> _getHeaders() {
    return {
      'Authorization': 'Bearer $_accessToken',
      'Content-Type': 'application/json',
    };
  }

  // ✅ 1. TESTER LA CONNEXION
  static Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?limit=1'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur de connexion HubSpot: $e');
      return false;
    }
  }

  // 📖 2. RÉCUPÉRER LES TICKETS DEPUIS HUBSPOT
  static Future<List<dynamic>> getTickets() async {
    try {
      final url = Uri.parse(
        '$_baseUrl?properties=subject,content,hs_pipeline_stage,hs_ticket_priority,createdate&limit=10'
      );
      
      final response = await http.get(url, headers: _getHeaders());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ ${data['results']?.length ?? 0} tickets récupérés depuis HubSpot');
        return data['results'] ?? [];
      } else {
        print('❌ Erreur ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception: $e');
      return [];
    }
  }

  // ➕ 3. CRÉER UN TICKET DANS HUBSPOT (OPTIONNEL - POUR DÉMO)
  static Future<Map<String, dynamic>> createTicket({
    required String subject,
    required String description,
    required String priority,
    required String status,
  }) async {
    // Mapping des priorités HubSpot
    final priorityMap = {
      'Basse': 'LOW',
      'Moyenne': 'MEDIUM',
      'Haute': 'HIGH',
      'Critique': 'URGENT',
    };

    // Mapping des statuts HubSpot (pipeline par défaut)
    final stageMap = {
      'Nouveau': '1',
      'En attente': '2',
      'En cours': '3',
      'Résolu': '4',
      'Fermé': '5',
    };

    final body = jsonEncode({
      'properties': {
        'hs_pipeline': '0', // Pipeline par défaut
        'hs_pipeline_stage': stageMap[status] ?? '1',
        'hs_ticket_priority': priorityMap[priority] ?? 'MEDIUM',
        'subject': subject,
        'content': description,
      }
    });

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(),
        body: body,
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Ticket créé sur HubSpot avec ID: ${data['id']}');
        return {'success': true, 'id': data['id'], 'data': data};
      } else {
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 📚 4. BASE DE CONNAISSANCES - ARTICLES D'AIDE (DONNÉES LOCALES)
  // On utilise des données locales car HubSpot Knowledge Base nécessite un compte payant
  static List<Map<String, String>> getHelpArticles() {
    return [
      {
        'title': '📠 Imprimante ne fonctionne pas',
        'content': '1. Vérifiez que l\'imprimante est allumée\n2. Vérifiez les câbles USB/réseau\n3. Redémarrez l\'imprimante\n4. Contactez le SG au poste 1234',
        'category': 'Matériel',
        'icon': 'print',
      },
      {
        'title': '🌐 Connexion Wi-Fi instable',
        'content': '1. Déconnectez-vous et reconnectez-vous\n2. Oubliez le réseau et ressaisissez le mot de passe\n3. Redémarrez votre ordinateur\n4. Signalez l\'incident si persiste',
        'category': 'Réseau',
        'icon': 'wifi',
      },
      {
        'title': '🔑 Mot de passe oublié',
        'content': '1. Allez sur la page de connexion\n2. Cliquez sur "Mot de passe oublié"\n3. Suivez les instructions envoyées par email\n4. Contactez le support si besoin',
        'category': 'Compte',
        'icon': 'lock',
      },
      {
        'title': '💻 Ordinateur lent',
        'content': '1. Fermez les applications inutilisées\n2. Redémarrez votre ordinateur\n3. Vérifiez les mises à jour Windows\n4. Libérez de l\'espace disque',
        'category': 'Matériel',
        'icon': 'computer',
      },
      {
        'title': '📧 Problème de messagerie Outlook',
        'content': '1. Vérifiez votre connexion internet\n2. Redémarrez Outlook\n3. Vérifiez votre quota de stockage\n4. Contactez le SG pour une assistance',
        'category': 'Logiciel',
        'icon': 'email',
      },
    ];
  }

  // 🏷️ 5. FORMATEUR DE STATUT HUBSPOT VERS STATUT INCIDENT TRACK
  static String formatStatus(String? stageId) {
    switch (stageId) {
      case '1': return 'Nouveau';
      case '2': return 'En attente';
      case '3': return 'En cours';
      case '4': return 'Résolu';
      case '5': return 'Fermé';
      default: return 'Nouveau';
    }
  }

  // 🎨 6. COULEUR DE STATUT
  static Color getStatusColor(String status) {
    switch (status) {
      case 'Nouveau':
      case 'En attente':
        return const Color(0xFFD32F2F); // Rouge
      case 'En cours':
        return const Color(0xFFF57C00); // Orange
      case 'Résolu':
        return const Color(0xFF1976D2); // Bleu
      case 'Fermé':
        return const Color(0xFF757575); // Gris
      default:
        return const Color(0xFF757575);
    }
  }
}