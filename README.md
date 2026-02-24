# 🛠️ HelpDesk App

Une solution de gestion de tickets de support technique multi-plateforme, conçue pour optimiser l'assistance utilisateur et la résolution d'incidents en temps réel via une interface moderne et sécurisée.

## 📋 Description du Projet

Cette application implémente un système complet de gestion de maintenance. Elle permet aux utilisateurs de soumettre des tickets d'assistance et offre aux administrateurs ainsi qu'aux techniciens des outils de suivi performants pour garantir la continuité du service et une gestion efficace des flux de travail.

## 📁 Structure du Projet

```text
helpdesk_app/
├── android/              # Configuration native Android
├── assets/               # Ressources visuelles et images
├── lib/                  # Code source de l'application
│   ├── controllers/      # Logique métier et gestion d'état
│   ├── models/           # Modèles de données
│   ├── services/         # Services Firebase et notifications
│   ├── utils/            # Thèmes, couleurs et constantes
│   ├── views/            # Interfaces utilisateur (Écrans)
│   │   ├── admin/        # Dashboard et outils administrateur
│   │   ├── tech/         # Interface dédiée aux techniciens
│   │   ├── add_ticket_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   ├── help_center_view.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── notifications_screen.dart
│   │   ├── profile_screen.dart
│   │   └── register_screen.dart
│   ├── widgets/          # Composants UI réutilisables
│   ├── firebase_options.dart
│   └── main.dart         # Point d'entrée de l'application
├── firebase.json         # Configuration Firebase
├── pubspec.yaml          # Dépendances et métadonnées du projet
└── README.md             # Documentation du projet


