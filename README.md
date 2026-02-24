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


## 🚀 Installation et Configuration

### Prérequis

- **Flutter SDK** (Version stable)
- **Dart SDK**
- Un compte **Firebase** actif

### Étapes d'installation

1. **Cloner le repository**
   ```bash
   git clone https://github.com/votre-pseudo/helpdesk_app.git
   cd helpdesk_app
2. ** Installer les dépendances**
      flutter pub get
### 🔧 Configuration Firebase

1. **Créer un projet** : Rendez-vous sur la [Console Firebase](https://console.firebase.google.com/) et créez un nouveau projet.
2. **Activer l'Authentification** : Dans la section *Authentication*, activez les fournisseurs suivants :
    * Email/Mot de passe
    * Google
    * GitHub
3. **Base de données** : Initialisez une base de données **Cloud Firestore** en mode production ou test selon vos besoins.
4. **Configuration locale** : Utilisez la [CLI Firebase](https://firebase.google.com/docs/cli) pour générer automatiquement le fichier de configuration :
    ```bash
    flutterfire configure
    ```
    Cela mettra à jour votre fichier `lib/firebase_options.dart`.

## Lancement de l'application

Pour exécuter le projet sur la plateforme de votre choix, utilisez les commandes suivantes dans votre terminal :

* **Sur un appareil mobile (Émulateur ou physique) :**
    ```bash
    flutter run
    ```

* **Sur un navigateur Web (Idéal pour le Dashboard Admin) :**
    ```bash
    flutter run -d chrome
    ```

* **Sur Desktop (Windows) :**
    ```bash
    flutter run -d windows
    ```

> **Astuce :** Pour voir la liste de tous les appareils connectés disponibles, tapez `flutter devices`.

## 📦 Technologies Utilisées

Le projet s'appuie sur un stack technologique moderne et robuste pour garantir performance et scalabilité :

* **Framework :** [Flutter](https://flutter.dev/) - Pour un développement multi-plateforme (iOS, Android, Web, Desktop) avec un code source unique.
* **Backend :** [Firebase](https://firebase.google.com/) - Solution backend complète incluant :
    * **Authentication :** Gestion sécurisée des comptes (Email, Google, GitHub).
    * **Cloud Firestore :** Base de données NoSQL en temps réel pour la synchronisation des tickets.
    * **Cloud Messaging (FCM) :** Envoi de notifications push pour le suivi des incidents.
* **Gestion d'état (State Management) :** [Provider](https://pub.dev/packages/provider) - Pour une gestion fluide et réactive des données à travers l'application.
* **Stockage Local :** [Shared Preferences](https://pub.dev/packages/shared_preferences) - Pour la persistance des sessions utilisateur et des réglages locaux.
* **Design :** [Material 3](https://m3.material.io/) - Pour une interface utilisateur moderne, épurée et adaptative.

## 🛠️ Fonctionnalités Principales

L'application offre une expérience complète adaptée à chaque profil d'utilisateur :

### 🔐 Système d'Authentification & Sécurité
* **Connexion Multi-mode :** Authentification classique par Email/Mot de passe ou via réseaux sociaux (**Google** et **GitHub**).
* **Gestion des Rôles :** Redirection automatique vers l'interface appropriée selon le profil (**Administrateur**, **Technicien** ou **Utilisateur**).
* **Récupération de compte :** Système intégré de réinitialisation de mot de passe oublié.

### 🎫 Gestion Intelligente des Tickets
* **Soumission d'Incidents :** Formulaire intuitif pour décrire le problème et définir le niveau de priorité.
* **Suivi en Temps Réel :** Consultation de l'état d'avancement des tickets (Ouvert, En cours, Résolu).
* **Notifications Push :** Alertes instantanées pour informer l'utilisateur de l'évolution de sa demande.

### 🏠 Interfaces Dédiées
* **Dashboard Admin :** Vue d'ensemble pour la gestion globale, les statistiques et l'administration des utilisateurs.
* **Espace Technicien :** Liste de tâches optimisée pour traiter les tickets assignés rapidement.
* **Centre d'Aide :** Section dédiée aux ressources et à l'assistance directe.

### 📱 Expérience Adaptative
* **Responsive Design :** Interface totalement fluide qui s'adapte aussi bien aux écrans de smartphones (Android/iOS) qu'aux navigateurs web et ordinateurs de bureau.

## 👨‍💻 Auteurs

Ce projet a été réalisé avec passion par :

* **LUTHOMO IBELE BLESSING**
* **NKURA KIKAKALA WINNER** 
* **NGANDU KASHINDA FRANCK** -
* **NAWEZI TUBALA EULOGIA** 
* **WASSO KISEMBE VICTORINA** 


**Dernière mise à jour** : Février 2026
