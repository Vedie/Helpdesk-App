import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 1. Import nécessaire
import 'firebase_options.dart';
import 'controllers/ticket_controller.dart';
import 'controllers/auth_controller.dart';
import 'services/notification_service.dart';
import 'views/login_screen.dart';
import 'views/admin/dashboard_screen.dart';
import 'utils/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Charger le fichier .env AVANT toute autre chose
  // C'est ici que les clés API deviennent disponibles pour Firebase
  await dotenv.load(fileName: ".env");

  // 3. Initialisation de Firebase (utilise maintenant les clés du .env)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 4. Initialisation des Notifications (FCM)
  if (!kIsWeb) {
    await NotificationService.init();
  }

  runApp(const HelpDeskApp());
}

class HelpDeskApp extends StatelessWidget {
  const HelpDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TicketController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HelpDesk ONT',
        theme: ThemeData(
          useMaterial3: true,
          primaryColor: AppColors.blueONT,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.blueONT,
            brightness: Brightness.light,
          ),
          fontFamily: 'Roboto',
        ),
        // Logique de démarrage
        home: kIsWeb ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }
}